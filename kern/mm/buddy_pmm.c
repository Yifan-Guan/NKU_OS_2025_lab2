#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>

#define MAX_ORDER 10  // 最大阶数

static struct Page* manager_base;  // 管理的物理内存基地址
static size_t manager_n;           // 管理的物理页数量
static list_entry_t free_list[MAX_ORDER + 1];
static unsigned int nr_free = 0;

// 获取页的阶数
static inline size_t get_order(size_t n) {
    size_t order = 0;
    size_t size = 1;
    while (size < n) {
        order++;
        size <<= 1;
    }
    return order;
}

// 获取伙伴块的索引
static inline size_t get_buddy_index(size_t index, size_t order) {
    return index ^ (1 << order);
}

static inline int is_valid_buddy(struct Page* page, size_t order) {
    if (page == NULL || order >= MAX_ORDER) {
        return 0;
    }
    return PageProperty(page) && page->property == (1 << order);
}

static void
buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER; i++) {
        list_init(free_list + i);
    }
    nr_free = 0;
    manager_base = NULL;
    manager_n = 0;
}

static void
buddy_init_memmap(struct Page* base, size_t n) {
    assert(n > 0);
    struct Page* p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    
    // 如果是第一次初始化，设置管理器基地址
    if (manager_base == NULL) {
        manager_base = base;
        manager_n = n;
    }
    
    // 计算最大的可用阶数
    size_t total_pages = n;
    size_t current_order = MAX_ORDER;
    
    while (current_order > 0 && (1 << current_order) > total_pages) {
        current_order--;
    }
    
    // 将内存块添加到合适的空闲链表中
    size_t remaining_pages = total_pages;
    struct Page* current_base = base;
    
    while (remaining_pages > 0) {
        size_t block_size = (1 << current_order);
        while (block_size <= remaining_pages) {
            // 初始化块的第一页
            current_base->property = block_size;
            SetPageProperty(current_base);
            
            // 将块添加到对应阶数的空闲链表
            list_add(&(free_list[current_order]), &(current_base->page_link));
            nr_free += block_size;
            
            current_base += block_size;
            remaining_pages -= block_size;
        }
        if (current_order > 0) {
            current_order--;
        }
    }
}

static struct Page*
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    
    size_t required_order = get_order(n);
    if (required_order > MAX_ORDER) {
        return NULL;
    }
    
    size_t current_order = required_order;
    while (current_order <= MAX_ORDER) {
        if (!list_empty(&free_list[current_order])) {
            list_entry_t* le = list_next(&free_list[current_order]);
            struct Page* page = le2page(le, page_link);
            
            list_del(le);
            nr_free -= (1 << current_order);
            
            // 如果块太大，需要分割
            while (current_order > required_order) {
                current_order--;
                size_t buddy_index = get_buddy_index(page - manager_base, current_order);
                struct Page* buddy = manager_base + buddy_index;
                
                buddy->property = (1 << current_order);
                SetPageProperty(buddy);
                
                list_add(&free_list[current_order], &(buddy->page_link));
                nr_free += (1 << current_order);
            }
            
            // 设置分配块的属性
            page->property = n;
            ClearPageProperty(page);
            return page;
        }
        current_order++;
    }
    
    return NULL;
}

static void
buddy_free_pages(struct Page* base, size_t n) {
    assert(n > 0);
    assert(base >= manager_base && base < manager_base + manager_n);
    
    size_t index = base - manager_base;
    size_t order = get_order(n);
    
    size_t block_size = (1 << order);
    base->property = block_size;
    SetPageProperty(base);
    
    // 尝试合并伙伴块
    size_t current_order = order;
    while (current_order < MAX_ORDER) {
        size_t buddy_index = get_buddy_index(index, current_order);
        
        if (buddy_index >= manager_n) {
            break;
        }
        
        struct Page* buddy = manager_base + buddy_index;
        if (!is_valid_buddy(buddy, current_order)) {
            break;
        }
        
        buddy->property = 0;
        ClearPageProperty(buddy);
        list_del(&(buddy->page_link));
        
        // 确定合并后块的基地址（地址较小的那个）
        if (buddy < base) {
            base = buddy;
            index = buddy_index;
        }
        
        // 更新合并后块的属性
        current_order++;
        index = base - manager_base;
        base->property = (1 << current_order);
        SetPageProperty(base);
        
        nr_free -= (1 << (current_order - 1));  // 减去伙伴块的大小
    }
    
    list_add(&free_list[current_order], &(base->page_link));
    nr_free += (1 << current_order);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
basic_check(void) {
    // 基本检查逻辑保持不变，确保与原有测试兼容
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    free_page(p0);
    free_page(p1);
    free_page(p2);
}

static void
buddy_check(void) {

    basic_check();

    struct Page *p0 = alloc_pages(5);
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    free_pages(p0, 5);

}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};