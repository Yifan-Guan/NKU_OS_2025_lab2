#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>

/* SLUB分配器实现
 * SLUB是Linux内核中使用的高效内存分配器，特点：
 * 1. 基于对象缓存的概念
 * 2. 每个CPU有本地缓存
 * 3. 支持不同大小的对象分配
 * 4. 减少内存碎片
 */

#define SLUB_MIN_SIZE 16
#define SLUB_MAX_SIZE 2048
#define SLUB_SIZE_COUNT 8  // 8种不同大小的缓存

// SLUB缓存描述符
typedef struct kmem_cache {
    char name[16];              // 缓存名称
    size_t objsize;            // 对象大小
    size_t size;               // 实际分配大小（包含元数据）
    unsigned int num;          // 每个slab中的对象数量
    struct slab *slabs_full;   // 满slab列表
    struct slab *slabs_partial;// 部分空slab列表  
    struct slab *slabs_free;   // 空slab列表
    int offset;                // 空闲指针偏移量
} kmem_cache_t;

// SLAB描述符
typedef struct slab {
    struct slab *next;         // 下一个slab
    void *freelist;            // 空闲对象链表
    int inuse;                 // 已使用对象数量
    int free;                  // 空闲对象数量
    void *base;                // slab基地址
    kmem_cache_t *cache;       // 所属缓存
} slab_t;

// 全局SLUB缓存数组
static kmem_cache_t slub_caches[SLUB_SIZE_COUNT];
static size_t slub_sizes[SLUB_SIZE_COUNT] = {16, 32, 64, 128, 256, 512, 1024, 2048};

static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 初始化SLUB分配器
static void
slub_init(void) {
    list_init(&free_list);
    nr_free = 0;
    
    // 初始化各种大小的缓存
    for (int i = 0; i < SLUB_SIZE_COUNT; i++) {
        kmem_cache_t *cache = &slub_caches[i];
        cache->objsize = slub_sizes[i];
        cache->size = slub_sizes[i] + sizeof(void*); // 额外空间存放空闲指针
        cache->num = (PGSIZE - sizeof(slab_t)) / cache->size; // 计算每个slab的对象数量
        cache->offset = sizeof(void*); // 空闲指针偏移
        
        cache->slabs_full = NULL;
        cache->slabs_partial = NULL;
        cache->slabs_free = NULL;
    }
}

// 初始化内存映射
static void
slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    
    // 将页面添加到空闲列表（SLUB在需要时从这里分配slab）
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

// 从空闲列表分配连续页面
static struct Page *
alloc_pages_from_free_list(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

// 创建新的slab
static slab_t *
slub_new_slab(kmem_cache_t *cache) {
    // 分配一个页面作为slab
    struct Page *page = alloc_pages_from_free_list(1);
    if (page == NULL) {
        return NULL;
    }
    
    slab_t *slab = (slab_t *)page2pa(page);
    slab->base = (void *)slab;
    slab->cache = cache;
    slab->inuse = 0;
    slab->free = cache->num;
    slab->next = NULL;
    
    // 初始化空闲链表
    slab->freelist = (void *)((char *)slab + sizeof(slab_t));
    void **current = (void **)slab->freelist;
    
    for (unsigned int i = 0; i < cache->num - 1; i++) {
        void *next = (char *)current + cache->size;
        *current = next;
        current = (void **)next;
    }
    *current = NULL; // 最后一个指向NULL
    
    return slab;
}

// 从缓存分配对象
static void *
slub_alloc(kmem_cache_t *cache) {
    void *object = NULL;
    
    // 首先尝试从partial slab分配
    slab_t *slab = cache->slabs_partial;
    if (slab != NULL) {
        object = slab->freelist;
        if (object != NULL) {
            slab->freelist = *(void **)object;
            slab->inuse++;
            slab->free--;
            
            if (slab->free == 0) {
                cache->slabs_partial = slab->next;
                slab->next = cache->slabs_full;
                cache->slabs_full = slab;
            }
            return object;
        }
    }
    
    // 尝试从free slab分配
    slab = cache->slabs_free;
    if (slab != NULL) {
        object = slab->freelist;
        if (object != NULL) {
            slab->freelist = *(void **)object;
            slab->inuse++;
            slab->free--;
            
            cache->slabs_free = slab->next;
            slab->next = cache->slabs_partial;
            cache->slabs_partial = slab;
            return object;
        }
    }
    
    // 需要创建新的slab
    slab = slub_new_slab(cache);
    if (slab != NULL) {
        object = slab->freelist;
        if (object != NULL) {
            slab->freelist = *(void **)object;
            slab->inuse++;
            slab->free--;
            
            slab->next = cache->slabs_partial;
            cache->slabs_partial = slab;
            return object;
        }
    }
    
    return NULL;
}

// 释放对象到缓存
static void
slub_free(kmem_cache_t *cache, void *object) {
    slab_t *slab = NULL;
    slab_t *prev = NULL;
    
    slab = cache->slabs_full;
    while (slab != NULL) {
        if (object >= slab->base && object < (void *)slab->base + PGSIZE) {
            break;
        }
        prev = slab;
        slab = slab->next;
    }
    
    // 在partial列表中查找
    if (slab == NULL) {
        slab = cache->slabs_partial;
        prev = NULL;
        while (slab != NULL) {
            if (object >= slab->base && object < (void *)slab->base + PGSIZE) {
                break;
            }
            prev = slab;
            slab = slab->next;
        }
    }
    
    if (slab == NULL) {
        return;
    }
    
    *(void **)object = slab->freelist;
    slab->freelist = object;
    slab->inuse--;
    slab->free++;
    
    // 根据slab状态调整列表
    if (slab->inuse == 0) {
        if (prev != NULL) {
            prev->next = slab->next;
        } else {
            if (slab == cache->slabs_full) {
                cache->slabs_full = slab->next;
            } else {
                cache->slabs_partial = slab->next;
            }
        }
        
        // 添加到free列表
        slab->next = cache->slabs_free;
        cache->slabs_free = slab;
        
        // 如果所有对象都释放了，可以考虑释放整个slab
        // 这里简化实现，保留slab以备后续使用
    } else if (slab->free == 1) {
        // 从full移到partial
        if (slab == cache->slabs_full) {
            cache->slabs_full = slab->next;
            slab->next = cache->slabs_partial;
            cache->slabs_partial = slab;
        }
    }
}

// 根据大小选择合适的缓存
static kmem_cache_t *
slub_get_cache(size_t n) {
    for (int i = 0; i < SLUB_SIZE_COUNT; i++) {
        if (n <= slub_sizes[i]) {
            return &slub_caches[i];
        }
    }
    return NULL; // 对于大对象，使用原始页面分配
}

static struct Page *
slub_alloc_pages(size_t n) {
    if (n == 0) {
        return NULL;
    }
    
    // 大对象分配：直接使用原始页面分配
    if (n >= PGSIZE) {
        size_t n_up = ROUNDUP(n, PGSIZE) / PGSIZE;
        return alloc_pages_from_free_list(n_up);
    }
    
    // 小对象分配：使用SLUB
    kmem_cache_t *cache = slub_get_cache(n);
    if (cache == NULL) {
        return NULL;
    }
    
    void *object = slub_alloc(cache);
    if (object == NULL) {
        return NULL;
    }
    
    struct Page *page = object;
    return page;
}

// SLUB释放页面
static void
slub_free_pages(struct Page *base, size_t n) {
    if (n == 0) {
        return;
    }
    
    // 大对象释放：直接释放到空闲列表
    if (n >= PGSIZE) {
        n = ROUNDUP(n, PGSIZE) / PGSIZE;
        struct Page *p = base;
        for (; p != base + n; p ++) {
            assert(!PageReserved(p) && !PageProperty(p));
            p->flags = 0;
            set_page_ref(p, 0);
        }
        base->property = n;
        SetPageProperty(base);
        nr_free += n;
        
        if (list_empty(&free_list)) {
            list_add(&free_list, &(base->page_link));
        } else {
            list_entry_t* le = &free_list;
            while ((le = list_next(le)) != &free_list) {
                struct Page* page = le2page(le, page_link);
                if (base < page) {
                    list_add_before(le, &(base->page_link));
                    break;
                } else if (list_next(le) == &free_list) {
                    list_add(le, &(base->page_link));
                }
            }
        }
        
        // 合并空闲块
        list_entry_t* le = list_prev(&(base->page_link));
        if (le != &free_list) {
            p = le2page(le, page_link);
            if (p + p->property == base) {
                p->property += base->property;
                ClearPageProperty(base);
                list_del(&(base->page_link));
                base = p;
            }
        }
        
        le = list_next(&(base->page_link));
        if (le != &free_list) {
            p = le2page(le, page_link);
            if (base + base->property == p) {
                base->property += p->property;
                ClearPageProperty(p);
                list_del(&(p->page_link));
            }
        }
        return;
    }
    
    // 小对象释放：使用SLUB
    kmem_cache_t *cache = slub_get_cache(n);
    if (cache != NULL) {
        void *object = base;
        slub_free(cache, object);
    }
}

static size_t
slub_nr_free_pages(void) {
    return nr_free;
}

static void
slub_basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    
    assert((p0 = slub_alloc_pages(1 * PGSIZE)) != NULL);
    assert((p1 = slub_alloc_pages(1 * PGSIZE)) != NULL);
    assert((p2 = slub_alloc_pages(1 * PGSIZE)) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    slub_free_pages(p0, 1);
    slub_free_pages(p1, 1);
    slub_free_pages(p2, 1);
}

static void
slub_default_check(void) {
    slub_basic_check();
    struct Page *p0;
    assert((p0 = slub_alloc_pages(22)) != NULL);
    slub_free_pages(p0, 22);
}

const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_default_check,
};
