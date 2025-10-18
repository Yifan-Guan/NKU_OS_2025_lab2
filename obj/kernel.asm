
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0203ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	fbc50513          	addi	a0,a0,-68 # ffffffffc0201008 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	fc650513          	addi	a0,a0,-58 # ffffffffc0201028 <etext+0x26>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	f9458593          	addi	a1,a1,-108 # ffffffffc0201002 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	fd250513          	addi	a0,a0,-46 # ffffffffc0201048 <etext+0x46>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	fde50513          	addi	a0,a0,-34 # ffffffffc0201068 <etext+0x66>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	fea50513          	addi	a0,a0,-22 # ffffffffc0201088 <etext+0x86>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00005797          	auipc	a5,0x5
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	fde50513          	addi	a0,a0,-34 # ffffffffc02010a8 <etext+0xa6>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_area>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	703000ef          	jal	ffffffffc0200ff0 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00001517          	auipc	a0,0x1
ffffffffc02000fe:	4be50513          	addi	a0,a0,1214 # ffffffffc02015b8 <etext+0x5b6>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	464000ef          	jal	ffffffffc020056e <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	2a5000ef          	jal	ffffffffc0200be0 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	271000ef          	jal	ffffffffc0200be0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00005317          	auipc	t1,0x5
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0205030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	ee850513          	addi	a0,a0,-280 # ffffffffc02010d8 <etext+0xd6>
    is_panic = 1;
ffffffffc02001f8:	00005697          	auipc	a3,0x5
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0205030 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	eea50513          	addi	a0,a0,-278 # ffffffffc02010f8 <etext+0xf6>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	5230006f          	j	ffffffffc0200f46 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	ed650513          	addi	a0,a0,-298 # ffffffffc0201100 <etext+0xfe>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00005597          	auipc	a1,0x5
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	ece50513          	addi	a0,a0,-306 # ffffffffc0201110 <etext+0x10e>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00005417          	auipc	s0,0x5
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0205008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	ec850513          	addi	a0,a0,-312 # ffffffffc0201120 <etext+0x11e>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	ed250513          	addi	a0,a0,-302 # ffffffffc0201138 <etext+0x136>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfedae75>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	ea850513          	addi	a0,a0,-344 # ffffffffc0201200 <etext+0x1fe>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	ed050513          	addi	a0,a0,-304 # ffffffffc0201238 <etext+0x236>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	ddc50513          	addi	a0,a0,-548 # ffffffffc0201158 <etext+0x156>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	39f000ef          	jal	ffffffffc0200f60 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	db458593          	addi	a1,a1,-588 # ffffffffc0201180 <etext+0x17e>
ffffffffc02003d4:	3f5000ef          	jal	ffffffffc0200fc8 <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	d9058593          	addi	a1,a1,-624 # ffffffffc0201188 <etext+0x186>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	367000ef          	jal	ffffffffc0200f94 <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	d4250513          	addi	a0,a0,-702 # ffffffffc0201190 <etext+0x18e>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	c9850513          	addi	a0,a0,-872 # ffffffffc02011b0 <etext+0x1ae>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02011c8 <etext+0x1c6>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	cac50513          	addi	a0,a0,-852 # ffffffffc02011e8 <etext+0x1e6>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00005797          	auipc	a5,0x5
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0205040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00005797          	auipc	a5,0x5
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0205038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00005517          	auipc	a0,0x5
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0205040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00005517          	auipc	a0,0x5
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0205038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <pmm_init>:
// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // pmm_manager = &default_pmm_manager;
    // pmm_manager = &best_fit_pmm_manager;
    // pmm_manager = &buddy_pmm_manager;
    pmm_manager = &slub_pmm_manager;
ffffffffc020056e:	00001797          	auipc	a5,0x1
ffffffffc0200572:	06a78793          	addi	a5,a5,106 # ffffffffc02015d8 <slub_pmm_manager>

    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200576:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200578:	7139                	addi	sp,sp,-64
ffffffffc020057a:	fc06                	sd	ra,56(sp)
ffffffffc020057c:	f822                	sd	s0,48(sp)
ffffffffc020057e:	f426                	sd	s1,40(sp)
ffffffffc0200580:	ec4e                	sd	s3,24(sp)
ffffffffc0200582:	f04a                	sd	s2,32(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc0200584:	00005417          	auipc	s0,0x5
ffffffffc0200588:	ac440413          	addi	s0,s0,-1340 # ffffffffc0205048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	cc450513          	addi	a0,a0,-828 # ffffffffc0201250 <etext+0x24e>
    pmm_manager = &slub_pmm_manager;
ffffffffc0200594:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200596:	bb3ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc020059a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020059c:	00005497          	auipc	s1,0x5
ffffffffc02005a0:	ac448493          	addi	s1,s1,-1340 # ffffffffc0205060 <va_pa_offset>
    pmm_manager->init();
ffffffffc02005a4:	679c                	ld	a5,8(a5)
ffffffffc02005a6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02005a8:	57f5                	li	a5,-3
ffffffffc02005aa:	07fa                	slli	a5,a5,0x1e
ffffffffc02005ac:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02005ae:	fadff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc02005b2:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02005b4:	fb1ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02005b8:	14050b63          	beqz	a0,ffffffffc020070e <pmm_init+0x1a0>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02005bc:	00a98933          	add	s2,s3,a0
ffffffffc02005c0:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	cd650513          	addi	a0,a0,-810 # ffffffffc0201298 <etext+0x296>
ffffffffc02005ca:	b7fff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02005ce:	65a2                	ld	a1,8(sp)
ffffffffc02005d0:	864e                	mv	a2,s3
ffffffffc02005d2:	fff90693          	addi	a3,s2,-1
ffffffffc02005d6:	00001517          	auipc	a0,0x1
ffffffffc02005da:	cda50513          	addi	a0,a0,-806 # ffffffffc02012b0 <etext+0x2ae>
ffffffffc02005de:	b6bff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02005e2:	c80007b7          	lui	a5,0xc8000
ffffffffc02005e6:	85ca                	mv	a1,s2
ffffffffc02005e8:	0d27e163          	bltu	a5,s2,ffffffffc02006aa <pmm_init+0x13c>
ffffffffc02005ec:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02005ee:	00006697          	auipc	a3,0x6
ffffffffc02005f2:	a8968693          	addi	a3,a3,-1399 # ffffffffc0206077 <end+0xfff>
ffffffffc02005f6:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc02005f8:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02005fa:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc02005fe:	00005797          	auipc	a5,0x5
ffffffffc0200602:	a6b7b523          	sd	a1,-1430(a5) # ffffffffc0205068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200606:	00005797          	auipc	a5,0x5
ffffffffc020060a:	a6d7b523          	sd	a3,-1430(a5) # ffffffffc0205070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020060e:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200610:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200612:	02080963          	beqz	a6,ffffffffc0200644 <pmm_init+0xd6>
ffffffffc0200616:	00259613          	slli	a2,a1,0x2
ffffffffc020061a:	962e                	add	a2,a2,a1
ffffffffc020061c:	fec007b7          	lui	a5,0xfec00
ffffffffc0200620:	97b6                	add	a5,a5,a3
ffffffffc0200622:	060e                	slli	a2,a2,0x3
ffffffffc0200624:	963e                	add	a2,a2,a5
ffffffffc0200626:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200628:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020062a:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc020062e:	00176713          	ori	a4,a4,1
ffffffffc0200632:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200636:	fec799e3          	bne	a5,a2,ffffffffc0200628 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020063a:	00281793          	slli	a5,a6,0x2
ffffffffc020063e:	97c2                	add	a5,a5,a6
ffffffffc0200640:	078e                	slli	a5,a5,0x3
ffffffffc0200642:	96be                	add	a3,a3,a5
ffffffffc0200644:	c02007b7          	lui	a5,0xc0200
ffffffffc0200648:	0af6e763          	bltu	a3,a5,ffffffffc02006f6 <pmm_init+0x188>
ffffffffc020064c:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020064e:	77fd                	lui	a5,0xfffff
ffffffffc0200650:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200654:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200656:	0526ec63          	bltu	a3,s2,ffffffffc02006ae <pmm_init+0x140>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020065a:	601c                	ld	a5,0(s0)
ffffffffc020065c:	7b9c                	ld	a5,48(a5)
ffffffffc020065e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200660:	00001517          	auipc	a0,0x1
ffffffffc0200664:	cd850513          	addi	a0,a0,-808 # ffffffffc0201338 <etext+0x336>
ffffffffc0200668:	ae1ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020066c:	00004597          	auipc	a1,0x4
ffffffffc0200670:	99458593          	addi	a1,a1,-1644 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200674:	00005797          	auipc	a5,0x5
ffffffffc0200678:	9eb7b223          	sd	a1,-1564(a5) # ffffffffc0205058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020067c:	c02007b7          	lui	a5,0xc0200
ffffffffc0200680:	0af5e363          	bltu	a1,a5,ffffffffc0200726 <pmm_init+0x1b8>
ffffffffc0200684:	609c                	ld	a5,0(s1)
}
ffffffffc0200686:	7442                	ld	s0,48(sp)
ffffffffc0200688:	70e2                	ld	ra,56(sp)
ffffffffc020068a:	74a2                	ld	s1,40(sp)
ffffffffc020068c:	7902                	ld	s2,32(sp)
ffffffffc020068e:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200690:	40f586b3          	sub	a3,a1,a5
ffffffffc0200694:	00005797          	auipc	a5,0x5
ffffffffc0200698:	9ad7be23          	sd	a3,-1604(a5) # ffffffffc0205050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020069c:	00001517          	auipc	a0,0x1
ffffffffc02006a0:	cbc50513          	addi	a0,a0,-836 # ffffffffc0201358 <etext+0x356>
ffffffffc02006a4:	8636                	mv	a2,a3
}
ffffffffc02006a6:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02006a8:	b445                	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02006aa:	85be                	mv	a1,a5
ffffffffc02006ac:	b781                	j	ffffffffc02005ec <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02006ae:	6705                	lui	a4,0x1
ffffffffc02006b0:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02006b2:	96ba                	add	a3,a3,a4
ffffffffc02006b4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02006b6:	00c6d793          	srli	a5,a3,0xc
ffffffffc02006ba:	02b7f263          	bgeu	a5,a1,ffffffffc02006de <pmm_init+0x170>
    pmm_manager->init_memmap(base, n);
ffffffffc02006be:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02006c0:	fff80637          	lui	a2,0xfff80
ffffffffc02006c4:	97b2                	add	a5,a5,a2
ffffffffc02006c6:	00279513          	slli	a0,a5,0x2
ffffffffc02006ca:	953e                	add	a0,a0,a5
ffffffffc02006cc:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02006ce:	40d90933          	sub	s2,s2,a3
ffffffffc02006d2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02006d4:	00c95593          	srli	a1,s2,0xc
ffffffffc02006d8:	9546                	add	a0,a0,a7
ffffffffc02006da:	9782                	jalr	a5
}
ffffffffc02006dc:	bfbd                	j	ffffffffc020065a <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc02006de:	00001617          	auipc	a2,0x1
ffffffffc02006e2:	c2a60613          	addi	a2,a2,-982 # ffffffffc0201308 <etext+0x306>
ffffffffc02006e6:	06a00593          	li	a1,106
ffffffffc02006ea:	00001517          	auipc	a0,0x1
ffffffffc02006ee:	c3e50513          	addi	a0,a0,-962 # ffffffffc0201328 <etext+0x326>
ffffffffc02006f2:	ad7ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006f6:	00001617          	auipc	a2,0x1
ffffffffc02006fa:	bea60613          	addi	a2,a2,-1046 # ffffffffc02012e0 <etext+0x2de>
ffffffffc02006fe:	06400593          	li	a1,100
ffffffffc0200702:	00001517          	auipc	a0,0x1
ffffffffc0200706:	b8650513          	addi	a0,a0,-1146 # ffffffffc0201288 <etext+0x286>
ffffffffc020070a:	abfff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020070e:	00001617          	auipc	a2,0x1
ffffffffc0200712:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0201268 <etext+0x266>
ffffffffc0200716:	04c00593          	li	a1,76
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0201288 <etext+0x286>
ffffffffc0200722:	aa7ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200726:	86ae                	mv	a3,a1
ffffffffc0200728:	00001617          	auipc	a2,0x1
ffffffffc020072c:	bb860613          	addi	a2,a2,-1096 # ffffffffc02012e0 <etext+0x2de>
ffffffffc0200730:	07f00593          	li	a1,127
ffffffffc0200734:	00001517          	auipc	a0,0x1
ffffffffc0200738:	b5450513          	addi	a0,a0,-1196 # ffffffffc0201288 <etext+0x286>
ffffffffc020073c:	a8dff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200740 <slub_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200740:	00005797          	auipc	a5,0x5
ffffffffc0200744:	8d878793          	addi	a5,a5,-1832 # ffffffffc0205018 <free_area>
ffffffffc0200748:	e79c                	sd	a5,8(a5)
ffffffffc020074a:	e39c                	sd	a5,0(a5)

// 初始化SLUB分配器
static void
slub_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020074c:	0007a823          	sw	zero,16(a5)
        
        cache->slabs_full = NULL;
        cache->slabs_partial = NULL;
        cache->slabs_free = NULL;
    }
}
ffffffffc0200750:	8082                	ret

ffffffffc0200752 <slub_nr_free_pages>:
}

static size_t
slub_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200752:	00005517          	auipc	a0,0x5
ffffffffc0200756:	8d656503          	lwu	a0,-1834(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc020075a:	8082                	ret

ffffffffc020075c <alloc_pages_from_free_list>:
    assert(n > 0);
ffffffffc020075c:	cd41                	beqz	a0,ffffffffc02007f4 <alloc_pages_from_free_list+0x98>
    if (n > nr_free) {
ffffffffc020075e:	00005597          	auipc	a1,0x5
ffffffffc0200762:	8ca5a583          	lw	a1,-1846(a1) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200766:	86aa                	mv	a3,a0
ffffffffc0200768:	02059793          	slli	a5,a1,0x20
ffffffffc020076c:	9381                	srli	a5,a5,0x20
ffffffffc020076e:	00a7ef63          	bltu	a5,a0,ffffffffc020078c <alloc_pages_from_free_list+0x30>
    list_entry_t *le = &free_list;
ffffffffc0200772:	00005617          	auipc	a2,0x5
ffffffffc0200776:	8a660613          	addi	a2,a2,-1882 # ffffffffc0205018 <free_area>
ffffffffc020077a:	87b2                	mv	a5,a2
ffffffffc020077c:	a029                	j	ffffffffc0200786 <alloc_pages_from_free_list+0x2a>
        if (p->property >= n) {
ffffffffc020077e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200782:	00d77763          	bgeu	a4,a3,ffffffffc0200790 <alloc_pages_from_free_list+0x34>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200786:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200788:	fec79be3          	bne	a5,a2,ffffffffc020077e <alloc_pages_from_free_list+0x22>
        return NULL;
ffffffffc020078c:	4501                	li	a0,0
}
ffffffffc020078e:	8082                	ret
        if (page->property > n) {
ffffffffc0200790:	ff87a303          	lw	t1,-8(a5)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200794:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200798:	0087b883          	ld	a7,8(a5)
ffffffffc020079c:	02031713          	slli	a4,t1,0x20
ffffffffc02007a0:	9301                	srli	a4,a4,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02007a2:	01183423          	sd	a7,8(a6) # fffffffffff80008 <end+0x3fd7af90>
    next->prev = prev;
ffffffffc02007a6:	0108b023          	sd	a6,0(a7)
        struct Page *p = le2page(le, page_link);
ffffffffc02007aa:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02007ae:	02e6fb63          	bgeu	a3,a4,ffffffffc02007e4 <alloc_pages_from_free_list+0x88>
            struct Page *p = page + n;
ffffffffc02007b2:	00269713          	slli	a4,a3,0x2
ffffffffc02007b6:	9736                	add	a4,a4,a3
ffffffffc02007b8:	070e                	slli	a4,a4,0x3
ffffffffc02007ba:	972a                	add	a4,a4,a0
            SetPageProperty(p);
ffffffffc02007bc:	00873e03          	ld	t3,8(a4)
            p->property = page->property - n;
ffffffffc02007c0:	40d3033b          	subw	t1,t1,a3
ffffffffc02007c4:	00672823          	sw	t1,16(a4)
            SetPageProperty(p);
ffffffffc02007c8:	002e6313          	ori	t1,t3,2
ffffffffc02007cc:	00673423          	sd	t1,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc02007d0:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02007d4:	0068b023          	sd	t1,0(a7)
ffffffffc02007d8:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02007dc:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02007e0:	01073c23          	sd	a6,24(a4)
        ClearPageProperty(page);
ffffffffc02007e4:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc02007e8:	9d95                	subw	a1,a1,a3
ffffffffc02007ea:	ca0c                	sw	a1,16(a2)
        ClearPageProperty(page);
ffffffffc02007ec:	9b75                	andi	a4,a4,-3
ffffffffc02007ee:	fee7b823          	sd	a4,-16(a5)
ffffffffc02007f2:	8082                	ret
alloc_pages_from_free_list(size_t n) {
ffffffffc02007f4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02007f6:	00001697          	auipc	a3,0x1
ffffffffc02007fa:	ba268693          	addi	a3,a3,-1118 # ffffffffc0201398 <etext+0x396>
ffffffffc02007fe:	00001617          	auipc	a2,0x1
ffffffffc0200802:	ba260613          	addi	a2,a2,-1118 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200806:	06600593          	li	a1,102
ffffffffc020080a:	00001517          	auipc	a0,0x1
ffffffffc020080e:	bae50513          	addi	a0,a0,-1106 # ffffffffc02013b8 <etext+0x3b6>
alloc_pages_from_free_list(size_t n) {
ffffffffc0200812:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200814:	9b5ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200818 <slub_alloc_pages>:
    if (n == 0) {
ffffffffc0200818:	c111                	beqz	a0,ffffffffc020081c <slub_alloc_pages+0x4>
        return alloc_pages_from_free_list(n);
ffffffffc020081a:	b789                	j	ffffffffc020075c <alloc_pages_from_free_list>
}
ffffffffc020081c:	8082                	ret

ffffffffc020081e <slub_free_pages.part.0>:
        for (; p != base + n; p ++) {
ffffffffc020081e:	00259713          	slli	a4,a1,0x2
ffffffffc0200822:	972e                	add	a4,a4,a1
ffffffffc0200824:	070e                	slli	a4,a4,0x3
ffffffffc0200826:	00e506b3          	add	a3,a0,a4
ffffffffc020082a:	87aa                	mv	a5,a0
ffffffffc020082c:	cf09                	beqz	a4,ffffffffc0200846 <slub_free_pages.part.0+0x28>
            assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020082e:	6798                	ld	a4,8(a5)
ffffffffc0200830:	8b0d                	andi	a4,a4,3
ffffffffc0200832:	10071c63          	bnez	a4,ffffffffc020094a <slub_free_pages.part.0+0x12c>
            p->flags = 0;
ffffffffc0200836:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020083a:	0007a023          	sw	zero,0(a5)
        for (; p != base + n; p ++) {
ffffffffc020083e:	02878793          	addi	a5,a5,40
ffffffffc0200842:	fed796e3          	bne	a5,a3,ffffffffc020082e <slub_free_pages.part.0+0x10>
        SetPageProperty(base);
ffffffffc0200846:	00853883          	ld	a7,8(a0)
        nr_free += n;
ffffffffc020084a:	00004717          	auipc	a4,0x4
ffffffffc020084e:	7de72703          	lw	a4,2014(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200852:	00004697          	auipc	a3,0x4
ffffffffc0200856:	7c668693          	addi	a3,a3,1990 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc020085a:	669c                	ld	a5,8(a3)
        SetPageProperty(base);
ffffffffc020085c:	0028e613          	ori	a2,a7,2
        base->property = n;
ffffffffc0200860:	c90c                	sw	a1,16(a0)
        SetPageProperty(base);
ffffffffc0200862:	e510                	sd	a2,8(a0)
        nr_free += n;
ffffffffc0200864:	9f2d                	addw	a4,a4,a1
ffffffffc0200866:	ca98                	sw	a4,16(a3)
        if (list_empty(&free_list)) {
ffffffffc0200868:	0cd78663          	beq	a5,a3,ffffffffc0200934 <slub_free_pages.part.0+0x116>
                struct Page* page = le2page(le, page_link);
ffffffffc020086c:	fe878713          	addi	a4,a5,-24
ffffffffc0200870:	4801                	li	a6,0
ffffffffc0200872:	01850613          	addi	a2,a0,24
                if (base < page) {
ffffffffc0200876:	00e56a63          	bltu	a0,a4,ffffffffc020088a <slub_free_pages.part.0+0x6c>
    return listelm->next;
ffffffffc020087a:	6798                	ld	a4,8(a5)
                } else if (list_next(le) == &free_list) {
ffffffffc020087c:	06d70363          	beq	a4,a3,ffffffffc02008e2 <slub_free_pages.part.0+0xc4>
        for (; p != base + n; p ++) {
ffffffffc0200880:	87ba                	mv	a5,a4
                struct Page* page = le2page(le, page_link);
ffffffffc0200882:	fe878713          	addi	a4,a5,-24
                if (base < page) {
ffffffffc0200886:	fee57ae3          	bgeu	a0,a4,ffffffffc020087a <slub_free_pages.part.0+0x5c>
ffffffffc020088a:	00080463          	beqz	a6,ffffffffc0200892 <slub_free_pages.part.0+0x74>
ffffffffc020088e:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200892:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200896:	e390                	sd	a2,0(a5)
ffffffffc0200898:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc020089c:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc02008a0:	f11c                	sd	a5,32(a0)
        if (le != &free_list) {
ffffffffc02008a2:	02d80063          	beq	a6,a3,ffffffffc02008c2 <slub_free_pages.part.0+0xa4>
            if (p + p->property == base) {
ffffffffc02008a6:	ff882e03          	lw	t3,-8(a6)
            p = le2page(le, page_link);
ffffffffc02008aa:	fe880313          	addi	t1,a6,-24
            if (p + p->property == base) {
ffffffffc02008ae:	020e1613          	slli	a2,t3,0x20
ffffffffc02008b2:	9201                	srli	a2,a2,0x20
ffffffffc02008b4:	00261713          	slli	a4,a2,0x2
ffffffffc02008b8:	9732                	add	a4,a4,a2
ffffffffc02008ba:	070e                	slli	a4,a4,0x3
ffffffffc02008bc:	971a                	add	a4,a4,t1
ffffffffc02008be:	04e50d63          	beq	a0,a4,ffffffffc0200918 <slub_free_pages.part.0+0xfa>
        if (le != &free_list) {
ffffffffc02008c2:	00d78f63          	beq	a5,a3,ffffffffc02008e0 <slub_free_pages.part.0+0xc2>
            if (base + base->property == p) {
ffffffffc02008c6:	490c                	lw	a1,16(a0)
            p = le2page(le, page_link);
ffffffffc02008c8:	fe878693          	addi	a3,a5,-24
            if (base + base->property == p) {
ffffffffc02008cc:	02059613          	slli	a2,a1,0x20
ffffffffc02008d0:	9201                	srli	a2,a2,0x20
ffffffffc02008d2:	00261713          	slli	a4,a2,0x2
ffffffffc02008d6:	9732                	add	a4,a4,a2
ffffffffc02008d8:	070e                	slli	a4,a4,0x3
ffffffffc02008da:	972a                	add	a4,a4,a0
ffffffffc02008dc:	00e68d63          	beq	a3,a4,ffffffffc02008f6 <slub_free_pages.part.0+0xd8>
ffffffffc02008e0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02008e2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02008e4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02008e6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02008e8:	ed1c                	sd	a5,24(a0)
                    list_add(le, &(base->page_link));
ffffffffc02008ea:	8332                	mv	t1,a2
            while ((le = list_next(le)) != &free_list) {
ffffffffc02008ec:	04d70b63          	beq	a4,a3,ffffffffc0200942 <slub_free_pages.part.0+0x124>
ffffffffc02008f0:	4805                	li	a6,1
        for (; p != base + n; p ++) {
ffffffffc02008f2:	87ba                	mv	a5,a4
ffffffffc02008f4:	b779                	j	ffffffffc0200882 <slub_free_pages.part.0+0x64>
                base->property += p->property;
ffffffffc02008f6:	ff87a683          	lw	a3,-8(a5)
                ClearPageProperty(p);
ffffffffc02008fa:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02008fe:	0007b803          	ld	a6,0(a5)
ffffffffc0200902:	6790                	ld	a2,8(a5)
                base->property += p->property;
ffffffffc0200904:	9ead                	addw	a3,a3,a1
ffffffffc0200906:	c914                	sw	a3,16(a0)
                ClearPageProperty(p);
ffffffffc0200908:	9b75                	andi	a4,a4,-3
ffffffffc020090a:	fee7b823          	sd	a4,-16(a5)
    prev->next = next;
ffffffffc020090e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200912:	01063023          	sd	a6,0(a2)
        return;
ffffffffc0200916:	8082                	ret
                p->property += base->property;
ffffffffc0200918:	01c585bb          	addw	a1,a1,t3
ffffffffc020091c:	feb82c23          	sw	a1,-8(a6)
                ClearPageProperty(base);
ffffffffc0200920:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200924:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200928:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc020092c:	0107b023          	sd	a6,0(a5)
                base = p;
ffffffffc0200930:	851a                	mv	a0,t1
ffffffffc0200932:	bf41                	j	ffffffffc02008c2 <slub_free_pages.part.0+0xa4>
            list_add(&free_list, &(base->page_link));
ffffffffc0200934:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200938:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020093a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020093c:	e398                	sd	a4,0(a5)
ffffffffc020093e:	e798                	sd	a4,8(a5)
        if (le != &free_list) {
ffffffffc0200940:	8082                	ret
    return listelm->prev;
ffffffffc0200942:	883e                	mv	a6,a5
ffffffffc0200944:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200946:	87b6                	mv	a5,a3
ffffffffc0200948:	bfa9                	j	ffffffffc02008a2 <slub_free_pages.part.0+0x84>
slub_free_pages(struct Page *base, size_t n) {
ffffffffc020094a:	1141                	addi	sp,sp,-16
            assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020094c:	00001697          	auipc	a3,0x1
ffffffffc0200950:	a8468693          	addi	a3,a3,-1404 # ffffffffc02013d0 <etext+0x3ce>
ffffffffc0200954:	00001617          	auipc	a2,0x1
ffffffffc0200958:	a4c60613          	addi	a2,a2,-1460 # ffffffffc02013a0 <etext+0x39e>
ffffffffc020095c:	15100593          	li	a1,337
ffffffffc0200960:	00001517          	auipc	a0,0x1
ffffffffc0200964:	a5850513          	addi	a0,a0,-1448 # ffffffffc02013b8 <etext+0x3b6>
slub_free_pages(struct Page *base, size_t n) {
ffffffffc0200968:	e406                	sd	ra,8(sp)
            assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020096a:	85fff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020096e <slub_free_pages>:
    if (n == 0) {
ffffffffc020096e:	c191                	beqz	a1,ffffffffc0200972 <slub_free_pages+0x4>
ffffffffc0200970:	b57d                	j	ffffffffc020081e <slub_free_pages.part.0>
}
ffffffffc0200972:	8082                	ret

ffffffffc0200974 <slub_default_check>:
    slub_free_pages(p2, 1);
}

// 默认检查函数
static void
slub_default_check(void) {
ffffffffc0200974:	1101                	addi	sp,sp,-32
        return alloc_pages_from_free_list(n);
ffffffffc0200976:	4505                	li	a0,1
slub_default_check(void) {
ffffffffc0200978:	ec06                	sd	ra,24(sp)
ffffffffc020097a:	e822                	sd	s0,16(sp)
ffffffffc020097c:	e426                	sd	s1,8(sp)
ffffffffc020097e:	e04a                	sd	s2,0(sp)
        return alloc_pages_from_free_list(n);
ffffffffc0200980:	dddff0ef          	jal	ffffffffc020075c <alloc_pages_from_free_list>
    assert((p0 = slub_alloc_pages(1)) != NULL);
ffffffffc0200984:	0e050063          	beqz	a0,ffffffffc0200a64 <slub_default_check+0xf0>
ffffffffc0200988:	842a                	mv	s0,a0
        return alloc_pages_from_free_list(n);
ffffffffc020098a:	4505                	li	a0,1
ffffffffc020098c:	dd1ff0ef          	jal	ffffffffc020075c <alloc_pages_from_free_list>
ffffffffc0200990:	892a                	mv	s2,a0
    assert((p1 = slub_alloc_pages(1)) != NULL);
ffffffffc0200992:	c94d                	beqz	a0,ffffffffc0200a44 <slub_default_check+0xd0>
        return alloc_pages_from_free_list(n);
ffffffffc0200994:	4505                	li	a0,1
ffffffffc0200996:	dc7ff0ef          	jal	ffffffffc020075c <alloc_pages_from_free_list>
ffffffffc020099a:	84aa                	mv	s1,a0
    assert((p2 = slub_alloc_pages(1)) != NULL);
ffffffffc020099c:	c541                	beqz	a0,ffffffffc0200a24 <slub_default_check+0xb0>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020099e:	40a907b3          	sub	a5,s2,a0
ffffffffc02009a2:	40a40733          	sub	a4,s0,a0
ffffffffc02009a6:	0017b793          	seqz	a5,a5
ffffffffc02009aa:	00173713          	seqz	a4,a4
ffffffffc02009ae:	8fd9                	or	a5,a5,a4
ffffffffc02009b0:	ebb1                	bnez	a5,ffffffffc0200a04 <slub_default_check+0x90>
ffffffffc02009b2:	05240963          	beq	s0,s2,ffffffffc0200a04 <slub_default_check+0x90>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02009b6:	401c                	lw	a5,0(s0)
ffffffffc02009b8:	e795                	bnez	a5,ffffffffc02009e4 <slub_default_check+0x70>
ffffffffc02009ba:	00092783          	lw	a5,0(s2)
ffffffffc02009be:	e39d                	bnez	a5,ffffffffc02009e4 <slub_default_check+0x70>
ffffffffc02009c0:	411c                	lw	a5,0(a0)
ffffffffc02009c2:	e38d                	bnez	a5,ffffffffc02009e4 <slub_default_check+0x70>
    if (n == 0) {
ffffffffc02009c4:	8522                	mv	a0,s0
ffffffffc02009c6:	4585                	li	a1,1
ffffffffc02009c8:	e57ff0ef          	jal	ffffffffc020081e <slub_free_pages.part.0>
ffffffffc02009cc:	854a                	mv	a0,s2
ffffffffc02009ce:	4585                	li	a1,1
ffffffffc02009d0:	e4fff0ef          	jal	ffffffffc020081e <slub_free_pages.part.0>
    // 简化实现
    slub_basic_check();
}
ffffffffc02009d4:	6442                	ld	s0,16(sp)
ffffffffc02009d6:	60e2                	ld	ra,24(sp)
ffffffffc02009d8:	6902                	ld	s2,0(sp)
ffffffffc02009da:	8526                	mv	a0,s1
ffffffffc02009dc:	64a2                	ld	s1,8(sp)
ffffffffc02009de:	4585                	li	a1,1
ffffffffc02009e0:	6105                	addi	sp,sp,32
ffffffffc02009e2:	bd35                	j	ffffffffc020081e <slub_free_pages.part.0>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02009e4:	00001697          	auipc	a3,0x1
ffffffffc02009e8:	ab468693          	addi	a3,a3,-1356 # ffffffffc0201498 <etext+0x496>
ffffffffc02009ec:	00001617          	auipc	a2,0x1
ffffffffc02009f0:	9b460613          	addi	a2,a2,-1612 # ffffffffc02013a0 <etext+0x39e>
ffffffffc02009f4:	19900593          	li	a1,409
ffffffffc02009f8:	00001517          	auipc	a0,0x1
ffffffffc02009fc:	9c050513          	addi	a0,a0,-1600 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200a00:	fc8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a04:	00001697          	auipc	a3,0x1
ffffffffc0200a08:	a6c68693          	addi	a3,a3,-1428 # ffffffffc0201470 <etext+0x46e>
ffffffffc0200a0c:	00001617          	auipc	a2,0x1
ffffffffc0200a10:	99460613          	addi	a2,a2,-1644 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200a14:	19800593          	li	a1,408
ffffffffc0200a18:	00001517          	auipc	a0,0x1
ffffffffc0200a1c:	9a050513          	addi	a0,a0,-1632 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200a20:	fa8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = slub_alloc_pages(1)) != NULL);
ffffffffc0200a24:	00001697          	auipc	a3,0x1
ffffffffc0200a28:	a2468693          	addi	a3,a3,-1500 # ffffffffc0201448 <etext+0x446>
ffffffffc0200a2c:	00001617          	auipc	a2,0x1
ffffffffc0200a30:	97460613          	addi	a2,a2,-1676 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200a34:	19600593          	li	a1,406
ffffffffc0200a38:	00001517          	auipc	a0,0x1
ffffffffc0200a3c:	98050513          	addi	a0,a0,-1664 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200a40:	f88ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = slub_alloc_pages(1)) != NULL);
ffffffffc0200a44:	00001697          	auipc	a3,0x1
ffffffffc0200a48:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0201420 <etext+0x41e>
ffffffffc0200a4c:	00001617          	auipc	a2,0x1
ffffffffc0200a50:	95460613          	addi	a2,a2,-1708 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200a54:	19500593          	li	a1,405
ffffffffc0200a58:	00001517          	auipc	a0,0x1
ffffffffc0200a5c:	96050513          	addi	a0,a0,-1696 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200a60:	f68ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = slub_alloc_pages(1)) != NULL);
ffffffffc0200a64:	00001697          	auipc	a3,0x1
ffffffffc0200a68:	99468693          	addi	a3,a3,-1644 # ffffffffc02013f8 <etext+0x3f6>
ffffffffc0200a6c:	00001617          	auipc	a2,0x1
ffffffffc0200a70:	93460613          	addi	a2,a2,-1740 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200a74:	19400593          	li	a1,404
ffffffffc0200a78:	00001517          	auipc	a0,0x1
ffffffffc0200a7c:	94050513          	addi	a0,a0,-1728 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200a80:	f48ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200a84 <slub_init_memmap>:
slub_init_memmap(struct Page *base, size_t n) {
ffffffffc0200a84:	1141                	addi	sp,sp,-16
ffffffffc0200a86:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200a88:	c9e9                	beqz	a1,ffffffffc0200b5a <slub_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc0200a8a:	00259713          	slli	a4,a1,0x2
ffffffffc0200a8e:	972e                	add	a4,a4,a1
ffffffffc0200a90:	070e                	slli	a4,a4,0x3
ffffffffc0200a92:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200a96:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200a98:	cf11                	beqz	a4,ffffffffc0200ab4 <slub_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200a9a:	6798                	ld	a4,8(a5)
ffffffffc0200a9c:	8b05                	andi	a4,a4,1
ffffffffc0200a9e:	cf51                	beqz	a4,ffffffffc0200b3a <slub_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0200aa0:	0007a823          	sw	zero,16(a5)
ffffffffc0200aa4:	0007b423          	sd	zero,8(a5)
ffffffffc0200aa8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200aac:	02878793          	addi	a5,a5,40
ffffffffc0200ab0:	fed795e3          	bne	a5,a3,ffffffffc0200a9a <slub_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200ab4:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200ab6:	00004717          	auipc	a4,0x4
ffffffffc0200aba:	57272703          	lw	a4,1394(a4) # ffffffffc0205028 <free_area+0x10>
ffffffffc0200abe:	00004697          	auipc	a3,0x4
ffffffffc0200ac2:	55a68693          	addi	a3,a3,1370 # ffffffffc0205018 <free_area>
    return list->next == list;
ffffffffc0200ac6:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200ac8:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200acc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200ace:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200ad0:	9f2d                	addw	a4,a4,a1
ffffffffc0200ad2:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200ad4:	04d78663          	beq	a5,a3,ffffffffc0200b20 <slub_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200ad8:	fe878713          	addi	a4,a5,-24
ffffffffc0200adc:	4581                	li	a1,0
ffffffffc0200ade:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200ae2:	00e56a63          	bltu	a0,a4,ffffffffc0200af6 <slub_init_memmap+0x72>
    return listelm->next;
ffffffffc0200ae6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200ae8:	02d70263          	beq	a4,a3,ffffffffc0200b0c <slub_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0200aec:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200aee:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200af2:	fee57ae3          	bgeu	a0,a4,ffffffffc0200ae6 <slub_init_memmap+0x62>
ffffffffc0200af6:	c199                	beqz	a1,ffffffffc0200afc <slub_init_memmap+0x78>
ffffffffc0200af8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200afc:	6398                	ld	a4,0(a5)
}
ffffffffc0200afe:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200b00:	e390                	sd	a2,0(a5)
ffffffffc0200b02:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0200b04:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200b06:	f11c                	sd	a5,32(a0)
ffffffffc0200b08:	0141                	addi	sp,sp,16
ffffffffc0200b0a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200b0c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200b0e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200b10:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200b12:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200b14:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200b16:	00d70e63          	beq	a4,a3,ffffffffc0200b32 <slub_init_memmap+0xae>
ffffffffc0200b1a:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200b1c:	87ba                	mv	a5,a4
ffffffffc0200b1e:	bfc1                	j	ffffffffc0200aee <slub_init_memmap+0x6a>
}
ffffffffc0200b20:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200b22:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200b26:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200b28:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200b2a:	e398                	sd	a4,0(a5)
ffffffffc0200b2c:	e798                	sd	a4,8(a5)
}
ffffffffc0200b2e:	0141                	addi	sp,sp,16
ffffffffc0200b30:	8082                	ret
ffffffffc0200b32:	60a2                	ld	ra,8(sp)
ffffffffc0200b34:	e290                	sd	a2,0(a3)
ffffffffc0200b36:	0141                	addi	sp,sp,16
ffffffffc0200b38:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200b3a:	00001697          	auipc	a3,0x1
ffffffffc0200b3e:	99e68693          	addi	a3,a3,-1634 # ffffffffc02014d8 <etext+0x4d6>
ffffffffc0200b42:	00001617          	auipc	a2,0x1
ffffffffc0200b46:	85e60613          	addi	a2,a2,-1954 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200b4a:	04a00593          	li	a1,74
ffffffffc0200b4e:	00001517          	auipc	a0,0x1
ffffffffc0200b52:	86a50513          	addi	a0,a0,-1942 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200b56:	e72ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200b5a:	00001697          	auipc	a3,0x1
ffffffffc0200b5e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0201398 <etext+0x396>
ffffffffc0200b62:	00001617          	auipc	a2,0x1
ffffffffc0200b66:	83e60613          	addi	a2,a2,-1986 # ffffffffc02013a0 <etext+0x39e>
ffffffffc0200b6a:	04700593          	li	a1,71
ffffffffc0200b6e:	00001517          	auipc	a0,0x1
ffffffffc0200b72:	84a50513          	addi	a0,a0,-1974 # ffffffffc02013b8 <etext+0x3b6>
ffffffffc0200b76:	e52ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200b7a <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200b7a:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200b7c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200b80:	f022                	sd	s0,32(sp)
ffffffffc0200b82:	ec26                	sd	s1,24(sp)
ffffffffc0200b84:	e84a                	sd	s2,16(sp)
ffffffffc0200b86:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200b88:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200b8c:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200b8e:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200b92:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200b96:	84aa                	mv	s1,a0
ffffffffc0200b98:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0200b9a:	03067d63          	bgeu	a2,a6,ffffffffc0200bd4 <printnum+0x5a>
ffffffffc0200b9e:	e44e                	sd	s3,8(sp)
ffffffffc0200ba0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200ba2:	4785                	li	a5,1
ffffffffc0200ba4:	00e7d763          	bge	a5,a4,ffffffffc0200bb2 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0200ba8:	85ca                	mv	a1,s2
ffffffffc0200baa:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0200bac:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200bae:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200bb0:	fc65                	bnez	s0,ffffffffc0200ba8 <printnum+0x2e>
ffffffffc0200bb2:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200bb4:	00001797          	auipc	a5,0x1
ffffffffc0200bb8:	94c78793          	addi	a5,a5,-1716 # ffffffffc0201500 <etext+0x4fe>
ffffffffc0200bbc:	97d2                	add	a5,a5,s4
}
ffffffffc0200bbe:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200bc0:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0200bc4:	70a2                	ld	ra,40(sp)
ffffffffc0200bc6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200bc8:	85ca                	mv	a1,s2
ffffffffc0200bca:	87a6                	mv	a5,s1
}
ffffffffc0200bcc:	6942                	ld	s2,16(sp)
ffffffffc0200bce:	64e2                	ld	s1,24(sp)
ffffffffc0200bd0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200bd2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200bd4:	03065633          	divu	a2,a2,a6
ffffffffc0200bd8:	8722                	mv	a4,s0
ffffffffc0200bda:	fa1ff0ef          	jal	ffffffffc0200b7a <printnum>
ffffffffc0200bde:	bfd9                	j	ffffffffc0200bb4 <printnum+0x3a>

ffffffffc0200be0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200be0:	7119                	addi	sp,sp,-128
ffffffffc0200be2:	f4a6                	sd	s1,104(sp)
ffffffffc0200be4:	f0ca                	sd	s2,96(sp)
ffffffffc0200be6:	ecce                	sd	s3,88(sp)
ffffffffc0200be8:	e8d2                	sd	s4,80(sp)
ffffffffc0200bea:	e4d6                	sd	s5,72(sp)
ffffffffc0200bec:	e0da                	sd	s6,64(sp)
ffffffffc0200bee:	f862                	sd	s8,48(sp)
ffffffffc0200bf0:	fc86                	sd	ra,120(sp)
ffffffffc0200bf2:	f8a2                	sd	s0,112(sp)
ffffffffc0200bf4:	fc5e                	sd	s7,56(sp)
ffffffffc0200bf6:	f466                	sd	s9,40(sp)
ffffffffc0200bf8:	f06a                	sd	s10,32(sp)
ffffffffc0200bfa:	ec6e                	sd	s11,24(sp)
ffffffffc0200bfc:	84aa                	mv	s1,a0
ffffffffc0200bfe:	8c32                	mv	s8,a2
ffffffffc0200c00:	8a36                	mv	s4,a3
ffffffffc0200c02:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200c04:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200c08:	05500b13          	li	s6,85
ffffffffc0200c0c:	00001a97          	auipc	s5,0x1
ffffffffc0200c10:	a04a8a93          	addi	s5,s5,-1532 # ffffffffc0201610 <slub_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200c14:	000c4503          	lbu	a0,0(s8)
ffffffffc0200c18:	001c0413          	addi	s0,s8,1
ffffffffc0200c1c:	01350a63          	beq	a0,s3,ffffffffc0200c30 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0200c20:	cd0d                	beqz	a0,ffffffffc0200c5a <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0200c22:	85ca                	mv	a1,s2
ffffffffc0200c24:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200c26:	00044503          	lbu	a0,0(s0)
ffffffffc0200c2a:	0405                	addi	s0,s0,1
ffffffffc0200c2c:	ff351ae3          	bne	a0,s3,ffffffffc0200c20 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0200c30:	5cfd                	li	s9,-1
ffffffffc0200c32:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0200c34:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0200c38:	4b81                	li	s7,0
ffffffffc0200c3a:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200c3c:	00044683          	lbu	a3,0(s0)
ffffffffc0200c40:	00140c13          	addi	s8,s0,1
ffffffffc0200c44:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0200c48:	0ff5f593          	zext.b	a1,a1
ffffffffc0200c4c:	02bb6663          	bltu	s6,a1,ffffffffc0200c78 <vprintfmt+0x98>
ffffffffc0200c50:	058a                	slli	a1,a1,0x2
ffffffffc0200c52:	95d6                	add	a1,a1,s5
ffffffffc0200c54:	4198                	lw	a4,0(a1)
ffffffffc0200c56:	9756                	add	a4,a4,s5
ffffffffc0200c58:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0200c5a:	70e6                	ld	ra,120(sp)
ffffffffc0200c5c:	7446                	ld	s0,112(sp)
ffffffffc0200c5e:	74a6                	ld	s1,104(sp)
ffffffffc0200c60:	7906                	ld	s2,96(sp)
ffffffffc0200c62:	69e6                	ld	s3,88(sp)
ffffffffc0200c64:	6a46                	ld	s4,80(sp)
ffffffffc0200c66:	6aa6                	ld	s5,72(sp)
ffffffffc0200c68:	6b06                	ld	s6,64(sp)
ffffffffc0200c6a:	7be2                	ld	s7,56(sp)
ffffffffc0200c6c:	7c42                	ld	s8,48(sp)
ffffffffc0200c6e:	7ca2                	ld	s9,40(sp)
ffffffffc0200c70:	7d02                	ld	s10,32(sp)
ffffffffc0200c72:	6de2                	ld	s11,24(sp)
ffffffffc0200c74:	6109                	addi	sp,sp,128
ffffffffc0200c76:	8082                	ret
            putch('%', putdat);
ffffffffc0200c78:	85ca                	mv	a1,s2
ffffffffc0200c7a:	02500513          	li	a0,37
ffffffffc0200c7e:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0200c80:	fff44783          	lbu	a5,-1(s0)
ffffffffc0200c84:	02500713          	li	a4,37
ffffffffc0200c88:	8c22                	mv	s8,s0
ffffffffc0200c8a:	f8e785e3          	beq	a5,a4,ffffffffc0200c14 <vprintfmt+0x34>
ffffffffc0200c8e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0200c92:	1c7d                	addi	s8,s8,-1
ffffffffc0200c94:	fee79de3          	bne	a5,a4,ffffffffc0200c8e <vprintfmt+0xae>
ffffffffc0200c98:	bfb5                	j	ffffffffc0200c14 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0200c9a:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0200c9e:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0200ca0:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0200ca4:	fd06071b          	addiw	a4,a2,-48
ffffffffc0200ca8:	24e56a63          	bltu	a0,a4,ffffffffc0200efc <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0200cac:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200cae:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0200cb0:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0200cb4:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0200cb8:	0197073b          	addw	a4,a4,s9
ffffffffc0200cbc:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200cc0:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200cc2:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0200cc6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0200cc8:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0200ccc:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0200cd0:	feb570e3          	bgeu	a0,a1,ffffffffc0200cb0 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0200cd4:	f60d54e3          	bgez	s10,ffffffffc0200c3c <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0200cd8:	8d66                	mv	s10,s9
ffffffffc0200cda:	5cfd                	li	s9,-1
ffffffffc0200cdc:	b785                	j	ffffffffc0200c3c <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200cde:	8db6                	mv	s11,a3
ffffffffc0200ce0:	8462                	mv	s0,s8
ffffffffc0200ce2:	bfa9                	j	ffffffffc0200c3c <vprintfmt+0x5c>
ffffffffc0200ce4:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0200ce6:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0200ce8:	bf91                	j	ffffffffc0200c3c <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0200cea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200cec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200cf0:	00f74463          	blt	a4,a5,ffffffffc0200cf8 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0200cf4:	1a078763          	beqz	a5,ffffffffc0200ea2 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0200cf8:	000a3603          	ld	a2,0(s4)
ffffffffc0200cfc:	46c1                	li	a3,16
ffffffffc0200cfe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0200d00:	000d879b          	sext.w	a5,s11
ffffffffc0200d04:	876a                	mv	a4,s10
ffffffffc0200d06:	85ca                	mv	a1,s2
ffffffffc0200d08:	8526                	mv	a0,s1
ffffffffc0200d0a:	e71ff0ef          	jal	ffffffffc0200b7a <printnum>
            break;
ffffffffc0200d0e:	b719                	j	ffffffffc0200c14 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0200d10:	000a2503          	lw	a0,0(s4)
ffffffffc0200d14:	85ca                	mv	a1,s2
ffffffffc0200d16:	0a21                	addi	s4,s4,8
ffffffffc0200d18:	9482                	jalr	s1
            break;
ffffffffc0200d1a:	bded                	j	ffffffffc0200c14 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0200d1c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200d1e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200d22:	00f74463          	blt	a4,a5,ffffffffc0200d2a <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0200d26:	16078963          	beqz	a5,ffffffffc0200e98 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0200d2a:	000a3603          	ld	a2,0(s4)
ffffffffc0200d2e:	46a9                	li	a3,10
ffffffffc0200d30:	8a2e                	mv	s4,a1
ffffffffc0200d32:	b7f9                	j	ffffffffc0200d00 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0200d34:	85ca                	mv	a1,s2
ffffffffc0200d36:	03000513          	li	a0,48
ffffffffc0200d3a:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0200d3c:	85ca                	mv	a1,s2
ffffffffc0200d3e:	07800513          	li	a0,120
ffffffffc0200d42:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200d44:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0200d48:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200d4a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0200d4c:	bf55                	j	ffffffffc0200d00 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0200d4e:	85ca                	mv	a1,s2
ffffffffc0200d50:	02500513          	li	a0,37
ffffffffc0200d54:	9482                	jalr	s1
            break;
ffffffffc0200d56:	bd7d                	j	ffffffffc0200c14 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0200d58:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200d5c:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0200d5e:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0200d60:	bf95                	j	ffffffffc0200cd4 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0200d62:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200d64:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200d68:	00f74463          	blt	a4,a5,ffffffffc0200d70 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0200d6c:	12078163          	beqz	a5,ffffffffc0200e8e <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0200d70:	000a3603          	ld	a2,0(s4)
ffffffffc0200d74:	46a1                	li	a3,8
ffffffffc0200d76:	8a2e                	mv	s4,a1
ffffffffc0200d78:	b761                	j	ffffffffc0200d00 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0200d7a:	876a                	mv	a4,s10
ffffffffc0200d7c:	000d5363          	bgez	s10,ffffffffc0200d82 <vprintfmt+0x1a2>
ffffffffc0200d80:	4701                	li	a4,0
ffffffffc0200d82:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200d86:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0200d88:	bd55                	j	ffffffffc0200c3c <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0200d8a:	000d841b          	sext.w	s0,s11
ffffffffc0200d8e:	fd340793          	addi	a5,s0,-45
ffffffffc0200d92:	00f037b3          	snez	a5,a5
ffffffffc0200d96:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200d9a:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0200d9e:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200da0:	008a0793          	addi	a5,s4,8
ffffffffc0200da4:	e43e                	sd	a5,8(sp)
ffffffffc0200da6:	100d8c63          	beqz	s11,ffffffffc0200ebe <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0200daa:	12071363          	bnez	a4,ffffffffc0200ed0 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200dae:	000dc783          	lbu	a5,0(s11)
ffffffffc0200db2:	0007851b          	sext.w	a0,a5
ffffffffc0200db6:	c78d                	beqz	a5,ffffffffc0200de0 <vprintfmt+0x200>
ffffffffc0200db8:	0d85                	addi	s11,s11,1
ffffffffc0200dba:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200dbc:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200dc0:	000cc563          	bltz	s9,ffffffffc0200dca <vprintfmt+0x1ea>
ffffffffc0200dc4:	3cfd                	addiw	s9,s9,-1
ffffffffc0200dc6:	008c8d63          	beq	s9,s0,ffffffffc0200de0 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200dca:	020b9663          	bnez	s7,ffffffffc0200df6 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0200dce:	85ca                	mv	a1,s2
ffffffffc0200dd0:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200dd2:	000dc783          	lbu	a5,0(s11)
ffffffffc0200dd6:	0d85                	addi	s11,s11,1
ffffffffc0200dd8:	3d7d                	addiw	s10,s10,-1
ffffffffc0200dda:	0007851b          	sext.w	a0,a5
ffffffffc0200dde:	f3ed                	bnez	a5,ffffffffc0200dc0 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0200de0:	01a05963          	blez	s10,ffffffffc0200df2 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0200de4:	85ca                	mv	a1,s2
ffffffffc0200de6:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0200dea:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0200dec:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0200dee:	fe0d1be3          	bnez	s10,ffffffffc0200de4 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200df2:	6a22                	ld	s4,8(sp)
ffffffffc0200df4:	b505                	j	ffffffffc0200c14 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200df6:	3781                	addiw	a5,a5,-32
ffffffffc0200df8:	fcfa7be3          	bgeu	s4,a5,ffffffffc0200dce <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0200dfc:	03f00513          	li	a0,63
ffffffffc0200e00:	85ca                	mv	a1,s2
ffffffffc0200e02:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200e04:	000dc783          	lbu	a5,0(s11)
ffffffffc0200e08:	0d85                	addi	s11,s11,1
ffffffffc0200e0a:	3d7d                	addiw	s10,s10,-1
ffffffffc0200e0c:	0007851b          	sext.w	a0,a5
ffffffffc0200e10:	dbe1                	beqz	a5,ffffffffc0200de0 <vprintfmt+0x200>
ffffffffc0200e12:	fa0cd9e3          	bgez	s9,ffffffffc0200dc4 <vprintfmt+0x1e4>
ffffffffc0200e16:	b7c5                	j	ffffffffc0200df6 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0200e18:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0200e1c:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0200e1e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0200e20:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0200e24:	8fb9                	xor	a5,a5,a4
ffffffffc0200e26:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0200e2a:	02d64563          	blt	a2,a3,ffffffffc0200e54 <vprintfmt+0x274>
ffffffffc0200e2e:	00001797          	auipc	a5,0x1
ffffffffc0200e32:	93a78793          	addi	a5,a5,-1734 # ffffffffc0201768 <error_string>
ffffffffc0200e36:	00369713          	slli	a4,a3,0x3
ffffffffc0200e3a:	97ba                	add	a5,a5,a4
ffffffffc0200e3c:	639c                	ld	a5,0(a5)
ffffffffc0200e3e:	cb99                	beqz	a5,ffffffffc0200e54 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0200e40:	86be                	mv	a3,a5
ffffffffc0200e42:	00000617          	auipc	a2,0x0
ffffffffc0200e46:	6ee60613          	addi	a2,a2,1774 # ffffffffc0201530 <etext+0x52e>
ffffffffc0200e4a:	85ca                	mv	a1,s2
ffffffffc0200e4c:	8526                	mv	a0,s1
ffffffffc0200e4e:	0d8000ef          	jal	ffffffffc0200f26 <printfmt>
ffffffffc0200e52:	b3c9                	j	ffffffffc0200c14 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0200e54:	00000617          	auipc	a2,0x0
ffffffffc0200e58:	6cc60613          	addi	a2,a2,1740 # ffffffffc0201520 <etext+0x51e>
ffffffffc0200e5c:	85ca                	mv	a1,s2
ffffffffc0200e5e:	8526                	mv	a0,s1
ffffffffc0200e60:	0c6000ef          	jal	ffffffffc0200f26 <printfmt>
ffffffffc0200e64:	bb45                	j	ffffffffc0200c14 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0200e66:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200e68:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0200e6c:	00f74363          	blt	a4,a5,ffffffffc0200e72 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0200e70:	cf81                	beqz	a5,ffffffffc0200e88 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0200e72:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0200e76:	02044b63          	bltz	s0,ffffffffc0200eac <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0200e7a:	8622                	mv	a2,s0
ffffffffc0200e7c:	8a5e                	mv	s4,s7
ffffffffc0200e7e:	46a9                	li	a3,10
ffffffffc0200e80:	b541                	j	ffffffffc0200d00 <vprintfmt+0x120>
            lflag ++;
ffffffffc0200e82:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200e84:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0200e86:	bb5d                	j	ffffffffc0200c3c <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0200e88:	000a2403          	lw	s0,0(s4)
ffffffffc0200e8c:	b7ed                	j	ffffffffc0200e76 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0200e8e:	000a6603          	lwu	a2,0(s4)
ffffffffc0200e92:	46a1                	li	a3,8
ffffffffc0200e94:	8a2e                	mv	s4,a1
ffffffffc0200e96:	b5ad                	j	ffffffffc0200d00 <vprintfmt+0x120>
ffffffffc0200e98:	000a6603          	lwu	a2,0(s4)
ffffffffc0200e9c:	46a9                	li	a3,10
ffffffffc0200e9e:	8a2e                	mv	s4,a1
ffffffffc0200ea0:	b585                	j	ffffffffc0200d00 <vprintfmt+0x120>
ffffffffc0200ea2:	000a6603          	lwu	a2,0(s4)
ffffffffc0200ea6:	46c1                	li	a3,16
ffffffffc0200ea8:	8a2e                	mv	s4,a1
ffffffffc0200eaa:	bd99                	j	ffffffffc0200d00 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0200eac:	85ca                	mv	a1,s2
ffffffffc0200eae:	02d00513          	li	a0,45
ffffffffc0200eb2:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0200eb4:	40800633          	neg	a2,s0
ffffffffc0200eb8:	8a5e                	mv	s4,s7
ffffffffc0200eba:	46a9                	li	a3,10
ffffffffc0200ebc:	b591                	j	ffffffffc0200d00 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0200ebe:	e329                	bnez	a4,ffffffffc0200f00 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200ec0:	02800793          	li	a5,40
ffffffffc0200ec4:	853e                	mv	a0,a5
ffffffffc0200ec6:	00000d97          	auipc	s11,0x0
ffffffffc0200eca:	653d8d93          	addi	s11,s11,1619 # ffffffffc0201519 <etext+0x517>
ffffffffc0200ece:	b5f5                	j	ffffffffc0200dba <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0200ed0:	85e6                	mv	a1,s9
ffffffffc0200ed2:	856e                	mv	a0,s11
ffffffffc0200ed4:	0a4000ef          	jal	ffffffffc0200f78 <strnlen>
ffffffffc0200ed8:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0200edc:	01a05863          	blez	s10,ffffffffc0200eec <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0200ee0:	85ca                	mv	a1,s2
ffffffffc0200ee2:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0200ee4:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0200ee6:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0200ee8:	fe0d1ce3          	bnez	s10,ffffffffc0200ee0 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200eec:	000dc783          	lbu	a5,0(s11)
ffffffffc0200ef0:	0007851b          	sext.w	a0,a5
ffffffffc0200ef4:	ec0792e3          	bnez	a5,ffffffffc0200db8 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200ef8:	6a22                	ld	s4,8(sp)
ffffffffc0200efa:	bb29                	j	ffffffffc0200c14 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200efc:	8462                	mv	s0,s8
ffffffffc0200efe:	bbd9                	j	ffffffffc0200cd4 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0200f00:	85e6                	mv	a1,s9
ffffffffc0200f02:	00000517          	auipc	a0,0x0
ffffffffc0200f06:	61650513          	addi	a0,a0,1558 # ffffffffc0201518 <etext+0x516>
ffffffffc0200f0a:	06e000ef          	jal	ffffffffc0200f78 <strnlen>
ffffffffc0200f0e:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200f12:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0200f16:	00000d97          	auipc	s11,0x0
ffffffffc0200f1a:	602d8d93          	addi	s11,s11,1538 # ffffffffc0201518 <etext+0x516>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200f1e:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0200f20:	fda040e3          	bgtz	s10,ffffffffc0200ee0 <vprintfmt+0x300>
ffffffffc0200f24:	bd51                	j	ffffffffc0200db8 <vprintfmt+0x1d8>

ffffffffc0200f26 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0200f26:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0200f28:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0200f2c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0200f2e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0200f30:	ec06                	sd	ra,24(sp)
ffffffffc0200f32:	f83a                	sd	a4,48(sp)
ffffffffc0200f34:	fc3e                	sd	a5,56(sp)
ffffffffc0200f36:	e0c2                	sd	a6,64(sp)
ffffffffc0200f38:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200f3a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0200f3c:	ca5ff0ef          	jal	ffffffffc0200be0 <vprintfmt>
}
ffffffffc0200f40:	60e2                	ld	ra,24(sp)
ffffffffc0200f42:	6161                	addi	sp,sp,80
ffffffffc0200f44:	8082                	ret

ffffffffc0200f46 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0200f46:	00004717          	auipc	a4,0x4
ffffffffc0200f4a:	0ca73703          	ld	a4,202(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0200f4e:	4781                	li	a5,0
ffffffffc0200f50:	88ba                	mv	a7,a4
ffffffffc0200f52:	852a                	mv	a0,a0
ffffffffc0200f54:	85be                	mv	a1,a5
ffffffffc0200f56:	863e                	mv	a2,a5
ffffffffc0200f58:	00000073          	ecall
ffffffffc0200f5c:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0200f5e:	8082                	ret

ffffffffc0200f60 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0200f60:	00054783          	lbu	a5,0(a0)
ffffffffc0200f64:	cb81                	beqz	a5,ffffffffc0200f74 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0200f66:	4781                	li	a5,0
        cnt ++;
ffffffffc0200f68:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0200f6a:	00f50733          	add	a4,a0,a5
ffffffffc0200f6e:	00074703          	lbu	a4,0(a4)
ffffffffc0200f72:	fb7d                	bnez	a4,ffffffffc0200f68 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0200f74:	853e                	mv	a0,a5
ffffffffc0200f76:	8082                	ret

ffffffffc0200f78 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0200f78:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0200f7a:	e589                	bnez	a1,ffffffffc0200f84 <strnlen+0xc>
ffffffffc0200f7c:	a811                	j	ffffffffc0200f90 <strnlen+0x18>
        cnt ++;
ffffffffc0200f7e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0200f80:	00f58863          	beq	a1,a5,ffffffffc0200f90 <strnlen+0x18>
ffffffffc0200f84:	00f50733          	add	a4,a0,a5
ffffffffc0200f88:	00074703          	lbu	a4,0(a4)
ffffffffc0200f8c:	fb6d                	bnez	a4,ffffffffc0200f7e <strnlen+0x6>
ffffffffc0200f8e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0200f90:	852e                	mv	a0,a1
ffffffffc0200f92:	8082                	ret

ffffffffc0200f94 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0200f94:	00054783          	lbu	a5,0(a0)
ffffffffc0200f98:	e791                	bnez	a5,ffffffffc0200fa4 <strcmp+0x10>
ffffffffc0200f9a:	a01d                	j	ffffffffc0200fc0 <strcmp+0x2c>
ffffffffc0200f9c:	00054783          	lbu	a5,0(a0)
ffffffffc0200fa0:	cb99                	beqz	a5,ffffffffc0200fb6 <strcmp+0x22>
ffffffffc0200fa2:	0585                	addi	a1,a1,1
ffffffffc0200fa4:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0200fa8:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0200faa:	fef709e3          	beq	a4,a5,ffffffffc0200f9c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0200fae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0200fb2:	9d19                	subw	a0,a0,a4
ffffffffc0200fb4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0200fb6:	0015c703          	lbu	a4,1(a1)
ffffffffc0200fba:	4501                	li	a0,0
}
ffffffffc0200fbc:	9d19                	subw	a0,a0,a4
ffffffffc0200fbe:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0200fc0:	0005c703          	lbu	a4,0(a1)
ffffffffc0200fc4:	4501                	li	a0,0
ffffffffc0200fc6:	b7f5                	j	ffffffffc0200fb2 <strcmp+0x1e>

ffffffffc0200fc8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0200fc8:	ce01                	beqz	a2,ffffffffc0200fe0 <strncmp+0x18>
ffffffffc0200fca:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0200fce:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0200fd0:	cb91                	beqz	a5,ffffffffc0200fe4 <strncmp+0x1c>
ffffffffc0200fd2:	0005c703          	lbu	a4,0(a1)
ffffffffc0200fd6:	00f71763          	bne	a4,a5,ffffffffc0200fe4 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0200fda:	0505                	addi	a0,a0,1
ffffffffc0200fdc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0200fde:	f675                	bnez	a2,ffffffffc0200fca <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0200fe0:	4501                	li	a0,0
ffffffffc0200fe2:	8082                	ret
ffffffffc0200fe4:	00054503          	lbu	a0,0(a0)
ffffffffc0200fe8:	0005c783          	lbu	a5,0(a1)
ffffffffc0200fec:	9d1d                	subw	a0,a0,a5
}
ffffffffc0200fee:	8082                	ret

ffffffffc0200ff0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0200ff0:	ca01                	beqz	a2,ffffffffc0201000 <memset+0x10>
ffffffffc0200ff2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0200ff4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0200ff6:	0785                	addi	a5,a5,1
ffffffffc0200ff8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0200ffc:	fef61de3          	bne	a2,a5,ffffffffc0200ff6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201000:	8082                	ret
