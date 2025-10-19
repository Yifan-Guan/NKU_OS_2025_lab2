#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

#define MAX_ORDER 10       // 最大阶数，支持最大块大小为 2^10 = 1024页
#define BUDDY_NONE (-1)    // 无效伙伴标记

static struct Page* manager_base;  // 管理的物理内存基地址
static size_t manager_n;           // 管理的物理页数量
static free_area_t free_area[MAX_ORDER + 1];  // 按阶划分的空闲区域
static unsigned int nr_free = 0;   // 空闲物理页总数

// 计算2的幂次方
static inline size_t power_of_two(size_t order) {
    return 1 << order;
}

// 计算阶数（向上取整）
static inline size_t get_order(size_t n) {
    size_t order = 0;
    size_t size = 1;    
    while (size < n) {
        size <<= 1;
        order++;
    }
    return order;
}

// 计算伙伴块索引
static inline size_t buddy_index(size_t page_index, size_t order) {
    return page_index ^ (1 << order);
}

// 检查伙伴关系是否有效
static inline bool buddy_valid(struct Page *buddy, size_t order) {
    return buddy >= manager_base && 
           buddy < manager_base + manager_n &&
           PageProperty(buddy) && 
           buddy->property == power_of_two(order);
}

static void
buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER; i++) {
        list_init(&free_area[i].free_list);
        free_area[i].nr_free = 0;
    }
    nr_free = 0;
    manager_base = NULL;
    manager_n = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    manager_base = base;
    manager_n = n;    
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    
    // 将内存组织为最大可能的2的幂次方块
    size_t remaining_pages = n;
    struct Page *current = base;
    int current_order = MAX_ORDER;
    
    while (remaining_pages > 0 && current_order >= 0) {
        size_t block_size = power_of_two(current_order);        
        if (block_size <= remaining_pages) {
            // 初始化这个块
            current->property = block_size;
            SetPageProperty(current);
            
            // 添加到对应阶数的空闲链表
            list_add(&free_area[current_order].free_list, &(current->page_link));
            free_area[current_order].nr_free++;
            nr_free += block_size;            
            current += block_size;
            remaining_pages -= block_size;
        } else {
            current_order--;
        }
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);    
    if (n > nr_free) {
        return NULL;
    }
    
    // 计算所需阶数
    size_t required_order = get_order(n);
    if (required_order > MAX_ORDER) {
        return NULL;
    }
    
    // 从所需阶数开始搜索可用块
    size_t current_order = required_order;
    struct Page *page = NULL;    
    while (current_order <= MAX_ORDER) {
        if (!list_empty(&free_area[current_order].free_list)) {
            // 找到可用块
            list_entry_t *le = free_area[current_order].free_list.next;
            page = le2page(le, page_link);
            
            // 从链表中移除
            list_del(le);
            free_area[current_order].nr_free--;
            nr_free -= power_of_two(current_order);
            
            // 如果块太大，进行分割
            while (current_order > required_order) {
                current_order--;
                
                // 计算伙伴块索引
                struct Page *buddy = page + power_of_two(current_order);
                
                // 初始化伙伴块
                buddy->property = power_of_two(current_order);
                SetPageProperty(buddy);
                
                // 将伙伴块添加到对应空闲链表
                list_add(&free_area[current_order].free_list, &(buddy->page_link));
                free_area[current_order].nr_free++;
                nr_free += power_of_two(current_order);
            }
            
            // 设置分配块的属性
            page->property = power_of_two(required_order);
            ClearPageProperty(page);
            break;
        }
        current_order++;
    }    
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base >= manager_base && base < manager_base + manager_n);
    
    // 重新初始化释放的页面
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    
    // 计算块的实际阶数（必须是2的幂次方）
    size_t order = get_order(n);
    base->property = power_of_two(order);
    SetPageProperty(base);
    
    // 尝试合并伙伴块
    size_t current_order = order;
    struct Page *current_block = base;
    
    while (current_order < MAX_ORDER) {
        // 计算伙伴块索引
        size_t buddy_idx = buddy_index(current_block - manager_base, current_order);
        struct Page *buddy = manager_base + buddy_idx;
        
        // 检查伙伴块是否有效且空闲
        if (buddy_valid(buddy, current_order)) {
            // 从链表中移除伙伴块
            list_del(&(buddy->page_link));
            free_area[current_order].nr_free--;
            nr_free -= power_of_two(current_order);
            
            // 确定合并后的基地址（取两个块中地址较小的）
            if (current_block > buddy) {
                struct Page *temp = current_block;
                current_block = buddy;
                buddy = temp;
            }
            
            // 清除伙伴块的属性
            ClearPageProperty(buddy);
            buddy->property = 0;
            
            // 升级到下一阶
            current_order++;
            current_block->property = power_of_two(current_order);
        } else {
            break;
        }
    }
    
    // 将最终块添加到对应空闲链表
    list_add(&free_area[current_order].free_list, &(current_block->page_link));
    free_area[current_order].nr_free++;
    nr_free += power_of_two(current_order);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

// 调试函数：打印伙伴系统状态
static void
buddy_show(void) {
    cprintf("Buddy System Status:\n");
    cprintf("Total free pages: %u\n", nr_free);
    cprintf("Managed pages: %u\n", manager_n);    
    for (int i = 0; i <= MAX_ORDER; i++) {
        cprintf("Order %d (size %4u): %u free blocks\n", 
                i, power_of_two(i), free_area[i].nr_free);
        
        // 打印每个空闲块
        list_entry_t *le = &free_area[i].free_list;
        while ((le = list_next(le)) != &free_area[i].free_list) {
            struct Page *p = le2page(le, page_link);
            cprintf("  Block at page %ld, size %u\n", 
                    p - manager_base, p->property);
        }
    }
}

static void
basic_check(void) {
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
    cprintf("=== Buddy System Check ===\n");
    basic_check();
    
    // 分配和释放测试
    struct Page *p0, *p1, *p2;
    
    // 测试分配不同大小的块
    p0 = alloc_pages(1);  // 1页
    assert(p0 != NULL);
    p1 = alloc_pages(2);  // 2页  
    assert(p1 != NULL);
    p2 = alloc_pages(4);  // 4页
    assert(p2 != NULL);
    
    // 验证分配的正确性
    assert(p0->property == 1);
    assert(p1->property == 2);
    assert(p2->property == 4);
    
    // 释放并验证合并
    free_pages(p1, 2);
    free_pages(p0, 1);
    free_pages(p2, 4);
    
    // 分配大块测试合并效果
    struct Page *large = alloc_pages(8);
    assert(large != NULL);
    assert(large->property == 8);    
    free_pages(large, 8);    
    cprintf("buddy_check() succeeded!\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};