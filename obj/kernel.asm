
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
ffffffffc0200050:	1b450513          	addi	a0,a0,436 # ffffffffc0201200 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	1be50513          	addi	a0,a0,446 # ffffffffc0201220 <etext+0x24>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	18e58593          	addi	a1,a1,398 # ffffffffc02011fc <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	1ca50513          	addi	a0,a0,458 # ffffffffc0201240 <etext+0x44>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_list>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	1d650513          	addi	a0,a0,470 # ffffffffc0201260 <etext+0x64>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	09258593          	addi	a1,a1,146 # ffffffffc0205128 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	1e250513          	addi	a0,a0,482 # ffffffffc0201280 <etext+0x84>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00005797          	auipc	a5,0x5
ffffffffc02000b6:	47578793          	addi	a5,a5,1141 # ffffffffc0205527 <end+0x3ff>
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
ffffffffc02000ce:	1d650513          	addi	a0,a0,470 # ffffffffc02012a0 <etext+0xa4>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_list>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	04a60613          	addi	a2,a2,74 # ffffffffc0205128 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	0fc010ef          	jal	ffffffffc02011ea <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00001517          	auipc	a0,0x1
ffffffffc02000fe:	73e50513          	addi	a0,a0,1854 # ffffffffc0201838 <etext+0x63c>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	297000ef          	jal	ffffffffc0200ba0 <pmm_init>

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
ffffffffc020013c:	49f000ef          	jal	ffffffffc0200dda <vprintfmt>
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
ffffffffc0200170:	46b000ef          	jal	ffffffffc0200dda <vprintfmt>
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
ffffffffc02001cc:	f0032303          	lw	t1,-256(t1) # ffffffffc02050c8 <is_panic>
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
ffffffffc02001f4:	0e050513          	addi	a0,a0,224 # ffffffffc02012d0 <etext+0xd4>
    is_panic = 1;
ffffffffc02001f8:	00005697          	auipc	a3,0x5
ffffffffc02001fc:	ece6a823          	sw	a4,-304(a3) # ffffffffc02050c8 <is_panic>
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
ffffffffc0200212:	0e250513          	addi	a0,a0,226 # ffffffffc02012f0 <etext+0xf4>
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
ffffffffc0200224:	71d0006f          	j	ffffffffc0201140 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	0ce50513          	addi	a0,a0,206 # ffffffffc02012f8 <etext+0xfc>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00005597          	auipc	a1,0x5
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	0c650513          	addi	a0,a0,198 # ffffffffc0201308 <etext+0x10c>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00005417          	auipc	s0,0x5
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0205008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	0c050513          	addi	a0,a0,192 # ffffffffc0201318 <etext+0x11c>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	0ca50513          	addi	a0,a0,202 # ffffffffc0201330 <etext+0x134>
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
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfedadc5>
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
ffffffffc020035c:	0a050513          	addi	a0,a0,160 # ffffffffc02013f8 <etext+0x1fc>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	0c850513          	addi	a0,a0,200 # ffffffffc0201430 <etext+0x234>
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
ffffffffc0200380:	fd450513          	addi	a0,a0,-44 # ffffffffc0201350 <etext+0x154>
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
ffffffffc02003c2:	599000ef          	jal	ffffffffc020115a <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	fac58593          	addi	a1,a1,-84 # ffffffffc0201378 <etext+0x17c>
ffffffffc02003d4:	5ef000ef          	jal	ffffffffc02011c2 <strncmp>
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
ffffffffc02003fc:	f8858593          	addi	a1,a1,-120 # ffffffffc0201380 <etext+0x184>
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
ffffffffc020042e:	561000ef          	jal	ffffffffc020118e <strcmp>
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
ffffffffc0200452:	f3a50513          	addi	a0,a0,-198 # ffffffffc0201388 <etext+0x18c>
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
ffffffffc020051c:	e9050513          	addi	a0,a0,-368 # ffffffffc02013a8 <etext+0x1ac>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	e9650513          	addi	a0,a0,-362 # ffffffffc02013c0 <etext+0x1c4>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	ea450513          	addi	a0,a0,-348 # ffffffffc02013e0 <etext+0x1e4>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00005797          	auipc	a5,0x5
ffffffffc020054c:	b897b823          	sd	s1,-1136(a5) # ffffffffc02050d8 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00005797          	auipc	a5,0x5
ffffffffc0200554:	b887b023          	sd	s0,-1152(a5) # ffffffffc02050d0 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00005517          	auipc	a0,0x5
ffffffffc020055e:	b7e53503          	ld	a0,-1154(a0) # ffffffffc02050d8 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00005517          	auipc	a0,0x5
ffffffffc0200568:	b6c53503          	ld	a0,-1172(a0) # ffffffffc02050d0 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <buddy_init>:
    return PageProperty(page) && page->property == (1 << order);
}

static void
buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER; i++) {
ffffffffc020056e:	00005797          	auipc	a5,0x5
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0205018 <free_list>
ffffffffc0200576:	00005717          	auipc	a4,0x5
ffffffffc020057a:	b5270713          	addi	a4,a4,-1198 # ffffffffc02050c8 <is_panic>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020057e:	e79c                	sd	a5,8(a5)
ffffffffc0200580:	e39c                	sd	a5,0(a5)
ffffffffc0200582:	07c1                	addi	a5,a5,16
ffffffffc0200584:	fee79de3          	bne	a5,a4,ffffffffc020057e <buddy_init+0x10>
        list_init(free_list + i);
    }
    nr_free = 0;
ffffffffc0200588:	00005797          	auipc	a5,0x5
ffffffffc020058c:	b407ac23          	sw	zero,-1192(a5) # ffffffffc02050e0 <nr_free>
    manager_base = NULL;
ffffffffc0200590:	00005797          	auipc	a5,0x5
ffffffffc0200594:	b607b023          	sd	zero,-1184(a5) # ffffffffc02050f0 <manager_base>
    manager_n = 0;
ffffffffc0200598:	00005797          	auipc	a5,0x5
ffffffffc020059c:	b407b823          	sd	zero,-1200(a5) # ffffffffc02050e8 <manager_n>
}
ffffffffc02005a0:	8082                	ret

ffffffffc02005a2 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005a2:	00005517          	auipc	a0,0x5
ffffffffc02005a6:	b3e56503          	lwu	a0,-1218(a0) # ffffffffc02050e0 <nr_free>
ffffffffc02005aa:	8082                	ret

ffffffffc02005ac <buddy_free_pages>:
buddy_free_pages(struct Page* base, size_t n) {
ffffffffc02005ac:	1141                	addi	sp,sp,-16
ffffffffc02005ae:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02005b0:	14058d63          	beqz	a1,ffffffffc020070a <buddy_free_pages+0x15e>
    assert(base >= manager_base && base < manager_base + manager_n);
ffffffffc02005b4:	00005317          	auipc	t1,0x5
ffffffffc02005b8:	b3c33303          	ld	t1,-1220(t1) # ffffffffc02050f0 <manager_base>
ffffffffc02005bc:	12656763          	bltu	a0,t1,ffffffffc02006ea <buddy_free_pages+0x13e>
ffffffffc02005c0:	00005e97          	auipc	t4,0x5
ffffffffc02005c4:	b28ebe83          	ld	t4,-1240(t4) # ffffffffc02050e8 <manager_n>
ffffffffc02005c8:	002e9793          	slli	a5,t4,0x2
ffffffffc02005cc:	97f6                	add	a5,a5,t4
ffffffffc02005ce:	078e                	slli	a5,a5,0x3
ffffffffc02005d0:	979a                	add	a5,a5,t1
ffffffffc02005d2:	10f57c63          	bgeu	a0,a5,ffffffffc02006ea <buddy_free_pages+0x13e>
    while (size < n) {
ffffffffc02005d6:	4785                	li	a5,1
ffffffffc02005d8:	0ef58d63          	beq	a1,a5,ffffffffc02006d2 <buddy_free_pages+0x126>
    size_t order = 0;
ffffffffc02005dc:	4701                	li	a4,0
        size <<= 1;
ffffffffc02005de:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc02005e0:	0705                	addi	a4,a4,1
    while (size < n) {
ffffffffc02005e2:	feb7eee3          	bltu	a5,a1,ffffffffc02005de <buddy_free_pages+0x32>
    SetPageProperty(base);
ffffffffc02005e6:	6514                	ld	a3,8(a0)
    size_t block_size = (1 << order);
ffffffffc02005e8:	4785                	li	a5,1
ffffffffc02005ea:	00e7963b          	sllw	a2,a5,a4
    SetPageProperty(base);
ffffffffc02005ee:	0026e793          	ori	a5,a3,2
ffffffffc02005f2:	e51c                	sd	a5,8(a0)
    base->property = block_size;
ffffffffc02005f4:	c910                	sw	a2,16(a0)
    while (current_order < MAX_ORDER) {
ffffffffc02005f6:	47a5                	li	a5,9
ffffffffc02005f8:	0ee7e463          	bltu	a5,a4,ffffffffc02006e0 <buddy_free_pages+0x134>
    size_t index = base - manager_base;
ffffffffc02005fc:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200600:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac7ba5>
ffffffffc0200604:	02079f13          	slli	t5,a5,0x20
ffffffffc0200608:	40650e33          	sub	t3,a0,t1
ffffffffc020060c:	9f3e                	add	t5,t5,a5
ffffffffc020060e:	403e5693          	srai	a3,t3,0x3
ffffffffc0200612:	03e686b3          	mul	a3,a3,t5
ffffffffc0200616:	00005297          	auipc	t0,0x5
ffffffffc020061a:	aca2a283          	lw	t0,-1334(t0) # ffffffffc02050e0 <nr_free>
ffffffffc020061e:	4801                	li	a6,0
    return index ^ (1 << order);
ffffffffc0200620:	4585                	li	a1,1
    size_t index = base - manager_base;
ffffffffc0200622:	8896                	mv	a7,t0
    while (current_order < MAX_ORDER) {
ffffffffc0200624:	4fa9                	li	t6,10
    return index ^ (1 << order);
ffffffffc0200626:	00e597bb          	sllw	a5,a1,a4
ffffffffc020062a:	8ebd                	xor	a3,a3,a5
    return PageProperty(page) && page->property == (1 << order);
ffffffffc020062c:	863e                	mv	a2,a5
        if (buddy_index >= manager_n) {
ffffffffc020062e:	03d6f163          	bgeu	a3,t4,ffffffffc0200650 <buddy_free_pages+0xa4>
        struct Page* buddy = manager_base + buddy_index;
ffffffffc0200632:	00269793          	slli	a5,a3,0x2
ffffffffc0200636:	97b6                	add	a5,a5,a3
ffffffffc0200638:	078e                	slli	a5,a5,0x3
ffffffffc020063a:	979a                	add	a5,a5,t1
    if (page == NULL || order >= MAX_ORDER) {
ffffffffc020063c:	cb91                	beqz	a5,ffffffffc0200650 <buddy_free_pages+0xa4>
    return PageProperty(page) && page->property == (1 << order);
ffffffffc020063e:	6794                	ld	a3,8(a5)
ffffffffc0200640:	0026f393          	andi	t2,a3,2
ffffffffc0200644:	00038663          	beqz	t2,ffffffffc0200650 <buddy_free_pages+0xa4>
ffffffffc0200648:	0107a383          	lw	t2,16(a5)
ffffffffc020064c:	02c38b63          	beq	t2,a2,ffffffffc0200682 <buddy_free_pages+0xd6>
ffffffffc0200650:	00081363          	bnez	a6,ffffffffc0200656 <buddy_free_pages+0xaa>
ffffffffc0200654:	8896                	mv	a7,t0
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc0200656:	00005797          	auipc	a5,0x5
ffffffffc020065a:	9c278793          	addi	a5,a5,-1598 # ffffffffc0205018 <free_list>
ffffffffc020065e:	0712                	slli	a4,a4,0x4
ffffffffc0200660:	973e                	add	a4,a4,a5
ffffffffc0200662:	6714                	ld	a3,8(a4)
    list_add(&free_list[current_order], &(base->page_link));
ffffffffc0200664:	01850593          	addi	a1,a0,24
}
ffffffffc0200668:	60a2                	ld	ra,8(sp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020066a:	e28c                	sd	a1,0(a3)
ffffffffc020066c:	e70c                	sd	a1,8(a4)
    nr_free += (1 << current_order);
ffffffffc020066e:	011607bb          	addw	a5,a2,a7
ffffffffc0200672:	00005617          	auipc	a2,0x5
ffffffffc0200676:	a6f62723          	sw	a5,-1426(a2) # ffffffffc02050e0 <nr_free>
    elm->next = next;
ffffffffc020067a:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc020067c:	ed18                	sd	a4,24(a0)
}
ffffffffc020067e:	0141                	addi	sp,sp,16
ffffffffc0200680:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200682:	0187b803          	ld	a6,24(a5)
ffffffffc0200686:	7390                	ld	a2,32(a5)
        ClearPageProperty(buddy);
ffffffffc0200688:	9af5                	andi	a3,a3,-3
ffffffffc020068a:	e794                	sd	a3,8(a5)
        buddy->property = 0;
ffffffffc020068c:	0007a823          	sw	zero,16(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200690:	00c83423          	sd	a2,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc0200694:	01063023          	sd	a6,0(a2)
        if (buddy < base) {
ffffffffc0200698:	00a7f563          	bgeu	a5,a0,ffffffffc02006a2 <buddy_free_pages+0xf6>
ffffffffc020069c:	853e                	mv	a0,a5
ffffffffc020069e:	40678e33          	sub	t3,a5,t1
        SetPageProperty(base);
ffffffffc02006a2:	6514                	ld	a3,8(a0)
        current_order++;
ffffffffc02006a4:	0705                	addi	a4,a4,1
        nr_free -= (1 << (current_order - 1));  // 减去伙伴块的大小
ffffffffc02006a6:	fff7079b          	addiw	a5,a4,-1
        SetPageProperty(base);
ffffffffc02006aa:	0026e693          	ori	a3,a3,2
        base->property = (1 << current_order);
ffffffffc02006ae:	00e5963b          	sllw	a2,a1,a4
        nr_free -= (1 << (current_order - 1));  // 减去伙伴块的大小
ffffffffc02006b2:	00f597bb          	sllw	a5,a1,a5
        SetPageProperty(base);
ffffffffc02006b6:	e514                	sd	a3,8(a0)
        base->property = (1 << current_order);
ffffffffc02006b8:	c910                	sw	a2,16(a0)
        index = base - manager_base;
ffffffffc02006ba:	403e5693          	srai	a3,t3,0x3
ffffffffc02006be:	03e686b3          	mul	a3,a3,t5
        nr_free -= (1 << (current_order - 1));  // 减去伙伴块的大小
ffffffffc02006c2:	40f888bb          	subw	a7,a7,a5
ffffffffc02006c6:	4805                	li	a6,1
    while (current_order < MAX_ORDER) {
ffffffffc02006c8:	f5f71fe3          	bne	a4,t6,ffffffffc0200626 <buddy_free_pages+0x7a>
ffffffffc02006cc:	40000613          	li	a2,1024
ffffffffc02006d0:	b759                	j	ffffffffc0200656 <buddy_free_pages+0xaa>
    SetPageProperty(base);
ffffffffc02006d2:	651c                	ld	a5,8(a0)
    base->property = block_size;
ffffffffc02006d4:	c90c                	sw	a1,16(a0)
    size_t order = 0;
ffffffffc02006d6:	4701                	li	a4,0
    SetPageProperty(base);
ffffffffc02006d8:	0027e793          	ori	a5,a5,2
ffffffffc02006dc:	e51c                	sd	a5,8(a0)
    while (current_order < MAX_ORDER) {
ffffffffc02006de:	bf39                	j	ffffffffc02005fc <buddy_free_pages+0x50>
    nr_free += (1 << current_order);
ffffffffc02006e0:	00005897          	auipc	a7,0x5
ffffffffc02006e4:	a008a883          	lw	a7,-1536(a7) # ffffffffc02050e0 <nr_free>
ffffffffc02006e8:	b7bd                	j	ffffffffc0200656 <buddy_free_pages+0xaa>
    assert(base >= manager_base && base < manager_base + manager_n);
ffffffffc02006ea:	00001697          	auipc	a3,0x1
ffffffffc02006ee:	d9668693          	addi	a3,a3,-618 # ffffffffc0201480 <etext+0x284>
ffffffffc02006f2:	00001617          	auipc	a2,0x1
ffffffffc02006f6:	d5e60613          	addi	a2,a2,-674 # ffffffffc0201450 <etext+0x254>
ffffffffc02006fa:	08e00593          	li	a1,142
ffffffffc02006fe:	00001517          	auipc	a0,0x1
ffffffffc0200702:	d6a50513          	addi	a0,a0,-662 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200706:	ac3ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc020070a:	00001697          	auipc	a3,0x1
ffffffffc020070e:	d3e68693          	addi	a3,a3,-706 # ffffffffc0201448 <etext+0x24c>
ffffffffc0200712:	00001617          	auipc	a2,0x1
ffffffffc0200716:	d3e60613          	addi	a2,a2,-706 # ffffffffc0201450 <etext+0x254>
ffffffffc020071a:	08d00593          	li	a1,141
ffffffffc020071e:	00001517          	auipc	a0,0x1
ffffffffc0200722:	d4a50513          	addi	a0,a0,-694 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200726:	aa3ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020072a <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc020072a:	10050163          	beqz	a0,ffffffffc020082c <buddy_alloc_pages+0x102>
    if (n > nr_free) {
ffffffffc020072e:	00005317          	auipc	t1,0x5
ffffffffc0200732:	9b232303          	lw	t1,-1614(t1) # ffffffffc02050e0 <nr_free>
ffffffffc0200736:	02031793          	slli	a5,t1,0x20
ffffffffc020073a:	9381                	srli	a5,a5,0x20
ffffffffc020073c:	02a7ed63          	bltu	a5,a0,ffffffffc0200776 <buddy_alloc_pages+0x4c>
    while (size < n) {
ffffffffc0200740:	4785                	li	a5,1
    size_t order = 0;
ffffffffc0200742:	4681                	li	a3,0
    while (size < n) {
ffffffffc0200744:	00f50963          	beq	a0,a5,ffffffffc0200756 <buddy_alloc_pages+0x2c>
        size <<= 1;
ffffffffc0200748:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc020074a:	0685                	addi	a3,a3,1
    while (size < n) {
ffffffffc020074c:	fea7eee3          	bltu	a5,a0,ffffffffc0200748 <buddy_alloc_pages+0x1e>
    if (required_order > MAX_ORDER) {
ffffffffc0200750:	47a9                	li	a5,10
ffffffffc0200752:	02d7e263          	bltu	a5,a3,ffffffffc0200776 <buddy_alloc_pages+0x4c>
ffffffffc0200756:	00005717          	auipc	a4,0x5
ffffffffc020075a:	8c270713          	addi	a4,a4,-1854 # ffffffffc0205018 <free_list>
ffffffffc020075e:	00469793          	slli	a5,a3,0x4
ffffffffc0200762:	97ba                	add	a5,a5,a4
    while (current_order <= MAX_ORDER) {
ffffffffc0200764:	462d                	li	a2,11
    size_t current_order = required_order;
ffffffffc0200766:	8736                	mv	a4,a3
    return list->next == list;
ffffffffc0200768:	678c                	ld	a1,8(a5)
        if (!list_empty(&free_list[current_order])) {
ffffffffc020076a:	00f59963          	bne	a1,a5,ffffffffc020077c <buddy_alloc_pages+0x52>
        current_order++;
ffffffffc020076e:	0705                	addi	a4,a4,1
    while (current_order <= MAX_ORDER) {
ffffffffc0200770:	07c1                	addi	a5,a5,16
ffffffffc0200772:	fec71be3          	bne	a4,a2,ffffffffc0200768 <buddy_alloc_pages+0x3e>
        return NULL;
ffffffffc0200776:	4281                	li	t0,0
}
ffffffffc0200778:	8516                	mv	a0,t0
ffffffffc020077a:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020077c:	6190                	ld	a2,0(a1)
ffffffffc020077e:	659c                	ld	a5,8(a1)
            nr_free -= (1 << current_order);
ffffffffc0200780:	4f85                	li	t6,1
ffffffffc0200782:	00ef983b          	sllw	a6,t6,a4
ffffffffc0200786:	4103033b          	subw	t1,t1,a6
    prev->next = next;
ffffffffc020078a:	e61c                	sd	a5,8(a2)
ffffffffc020078c:	00005817          	auipc	a6,0x5
ffffffffc0200790:	94682a23          	sw	t1,-1708(a6) # ffffffffc02050e0 <nr_free>
    next->prev = prev;
ffffffffc0200794:	e390                	sd	a2,0(a5)
            struct Page* page = le2page(le, page_link);
ffffffffc0200796:	fe858293          	addi	t0,a1,-24
            while (current_order > required_order) {
ffffffffc020079a:	08e6f063          	bgeu	a3,a4,ffffffffc020081a <buddy_alloc_pages+0xf0>
                size_t buddy_index = get_buddy_index(page - manager_base, current_order);
ffffffffc020079e:	00005f17          	auipc	t5,0x5
ffffffffc02007a2:	952f3f03          	ld	t5,-1710(t5) # ffffffffc02050f0 <manager_base>
ffffffffc02007a6:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02007aa:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac7ba5>
ffffffffc02007ae:	02079613          	slli	a2,a5,0x20
ffffffffc02007b2:	41e28eb3          	sub	t4,t0,t5
ffffffffc02007b6:	97b2                	add	a5,a5,a2
ffffffffc02007b8:	403ede93          	srai	t4,t4,0x3
ffffffffc02007bc:	02fe8eb3          	mul	t4,t4,a5
ffffffffc02007c0:	00005617          	auipc	a2,0x5
ffffffffc02007c4:	84860613          	addi	a2,a2,-1976 # ffffffffc0205008 <boot_dtb>
ffffffffc02007c8:	00471793          	slli	a5,a4,0x4
ffffffffc02007cc:	963e                	add	a2,a2,a5
                current_order--;
ffffffffc02007ce:	177d                	addi	a4,a4,-1
    return index ^ (1 << order);
ffffffffc02007d0:	00ef983b          	sllw	a6,t6,a4
ffffffffc02007d4:	01d848b3          	xor	a7,a6,t4
                struct Page* buddy = manager_base + buddy_index;
ffffffffc02007d8:	00289793          	slli	a5,a7,0x2
ffffffffc02007dc:	97c6                	add	a5,a5,a7
ffffffffc02007de:	078e                	slli	a5,a5,0x3
ffffffffc02007e0:	97fa                	add	a5,a5,t5
                SetPageProperty(buddy);
ffffffffc02007e2:	0087b883          	ld	a7,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02007e6:	00863e03          	ld	t3,8(a2)
                buddy->property = (1 << current_order);
ffffffffc02007ea:	0107a823          	sw	a6,16(a5)
                SetPageProperty(buddy);
ffffffffc02007ee:	0028e893          	ori	a7,a7,2
ffffffffc02007f2:	0117b423          	sd	a7,8(a5)
                list_add(&free_list[current_order], &(buddy->page_link));
ffffffffc02007f6:	01878893          	addi	a7,a5,24
    prev->next = next->prev = elm;
ffffffffc02007fa:	011e3023          	sd	a7,0(t3)
ffffffffc02007fe:	01163423          	sd	a7,8(a2)
    elm->prev = prev;
ffffffffc0200802:	ef90                	sd	a2,24(a5)
    elm->next = next;
ffffffffc0200804:	03c7b023          	sd	t3,32(a5)
                nr_free += (1 << current_order);
ffffffffc0200808:	0068033b          	addw	t1,a6,t1
            while (current_order > required_order) {
ffffffffc020080c:	1641                	addi	a2,a2,-16
ffffffffc020080e:	fce690e3          	bne	a3,a4,ffffffffc02007ce <buddy_alloc_pages+0xa4>
ffffffffc0200812:	00005797          	auipc	a5,0x5
ffffffffc0200816:	8c67a723          	sw	t1,-1842(a5) # ffffffffc02050e0 <nr_free>
            ClearPageProperty(page);
ffffffffc020081a:	ff05b783          	ld	a5,-16(a1)
            page->property = n;
ffffffffc020081e:	fea5ac23          	sw	a0,-8(a1)
}
ffffffffc0200822:	8516                	mv	a0,t0
            ClearPageProperty(page);
ffffffffc0200824:	9bf5                	andi	a5,a5,-3
ffffffffc0200826:	fef5b823          	sd	a5,-16(a1)
}
ffffffffc020082a:	8082                	ret
buddy_alloc_pages(size_t n) {
ffffffffc020082c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020082e:	00001697          	auipc	a3,0x1
ffffffffc0200832:	c1a68693          	addi	a3,a3,-998 # ffffffffc0201448 <etext+0x24c>
ffffffffc0200836:	00001617          	auipc	a2,0x1
ffffffffc020083a:	c1a60613          	addi	a2,a2,-998 # ffffffffc0201450 <etext+0x254>
ffffffffc020083e:	06000593          	li	a1,96
ffffffffc0200842:	00001517          	auipc	a0,0x1
ffffffffc0200846:	c2650513          	addi	a0,a0,-986 # ffffffffc0201468 <etext+0x26c>
buddy_alloc_pages(size_t n) {
ffffffffc020084a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020084c:	97dff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200850 <buddy_init_memmap>:
buddy_init_memmap(struct Page* base, size_t n) {
ffffffffc0200850:	1141                	addi	sp,sp,-16
ffffffffc0200852:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200854:	c1e5                	beqz	a1,ffffffffc0200934 <buddy_init_memmap+0xe4>
    for (; p != base + n; p++) {
ffffffffc0200856:	00259713          	slli	a4,a1,0x2
ffffffffc020085a:	972e                	add	a4,a4,a1
ffffffffc020085c:	070e                	slli	a4,a4,0x3
ffffffffc020085e:	00e506b3          	add	a3,a0,a4
    struct Page* p = base;
ffffffffc0200862:	87aa                	mv	a5,a0
    for (; p != base + n; p++) {
ffffffffc0200864:	cf11                	beqz	a4,ffffffffc0200880 <buddy_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200866:	6798                	ld	a4,8(a5)
ffffffffc0200868:	8b05                	andi	a4,a4,1
ffffffffc020086a:	c74d                	beqz	a4,ffffffffc0200914 <buddy_init_memmap+0xc4>
        p->flags = p->property = 0;
ffffffffc020086c:	0007a823          	sw	zero,16(a5)
ffffffffc0200870:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200874:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0200878:	02878793          	addi	a5,a5,40
ffffffffc020087c:	fed795e3          	bne	a5,a3,ffffffffc0200866 <buddy_init_memmap+0x16>
    if (manager_base == NULL) {
ffffffffc0200880:	00005797          	auipc	a5,0x5
ffffffffc0200884:	8707b783          	ld	a5,-1936(a5) # ffffffffc02050f0 <manager_base>
ffffffffc0200888:	cfad                	beqz	a5,ffffffffc0200902 <buddy_init_memmap+0xb2>
    size_t current_order = MAX_ORDER;
ffffffffc020088a:	4329                	li	t1,10
    while (current_order > 0 && (1 << current_order) > total_pages) {
ffffffffc020088c:	4705                	li	a4,1
ffffffffc020088e:	006717bb          	sllw	a5,a4,t1
ffffffffc0200892:	00f5f563          	bgeu	a1,a5,ffffffffc020089c <buddy_init_memmap+0x4c>
        current_order--;
ffffffffc0200896:	137d                	addi	t1,t1,-1
    while (current_order > 0 && (1 << current_order) > total_pages) {
ffffffffc0200898:	fe031be3          	bnez	t1,ffffffffc020088e <buddy_init_memmap+0x3e>
    while (remaining_pages > 0) {
ffffffffc020089c:	00005817          	auipc	a6,0x5
ffffffffc02008a0:	84482803          	lw	a6,-1980(a6) # ffffffffc02050e0 <nr_free>
ffffffffc02008a4:	00004e97          	auipc	t4,0x4
ffffffffc02008a8:	774e8e93          	addi	t4,t4,1908 # ffffffffc0205018 <free_list>
        size_t block_size = (1 << current_order);
ffffffffc02008ac:	4e05                	li	t3,1
ffffffffc02008ae:	006e17bb          	sllw	a5,t3,t1
        while (block_size <= remaining_pages) {
ffffffffc02008b2:	02f5ec63          	bltu	a1,a5,ffffffffc02008ea <buddy_init_memmap+0x9a>
            current_base += block_size;
ffffffffc02008b6:	00279893          	slli	a7,a5,0x2
ffffffffc02008ba:	98be                	add	a7,a7,a5
            list_add(&(free_list[current_order]), &(current_base->page_link));
ffffffffc02008bc:	00431693          	slli	a3,t1,0x4
            current_base += block_size;
ffffffffc02008c0:	088e                	slli	a7,a7,0x3
            list_add(&(free_list[current_order]), &(current_base->page_link));
ffffffffc02008c2:	96f6                	add	a3,a3,t4
            SetPageProperty(current_base);
ffffffffc02008c4:	6518                	ld	a4,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008c6:	6690                	ld	a2,8(a3)
            current_base->property = block_size;
ffffffffc02008c8:	c91c                	sw	a5,16(a0)
            SetPageProperty(current_base);
ffffffffc02008ca:	00276713          	ori	a4,a4,2
ffffffffc02008ce:	e518                	sd	a4,8(a0)
            list_add(&(free_list[current_order]), &(current_base->page_link));
ffffffffc02008d0:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02008d4:	e218                	sd	a4,0(a2)
ffffffffc02008d6:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc02008d8:	f110                	sd	a2,32(a0)
    elm->prev = prev;
ffffffffc02008da:	ed14                	sd	a3,24(a0)
            remaining_pages -= block_size;
ffffffffc02008dc:	8d9d                	sub	a1,a1,a5
            nr_free += block_size;
ffffffffc02008de:	00f8083b          	addw	a6,a6,a5
            current_base += block_size;
ffffffffc02008e2:	9546                	add	a0,a0,a7
        while (block_size <= remaining_pages) {
ffffffffc02008e4:	fef5f0e3          	bgeu	a1,a5,ffffffffc02008c4 <buddy_init_memmap+0x74>
    while (remaining_pages > 0) {
ffffffffc02008e8:	c591                	beqz	a1,ffffffffc02008f4 <buddy_init_memmap+0xa4>
        if (current_order > 0) {
ffffffffc02008ea:	006037b3          	snez	a5,t1
ffffffffc02008ee:	40f30333          	sub	t1,t1,a5
ffffffffc02008f2:	bf75                	j	ffffffffc02008ae <buddy_init_memmap+0x5e>
}
ffffffffc02008f4:	60a2                	ld	ra,8(sp)
ffffffffc02008f6:	00004797          	auipc	a5,0x4
ffffffffc02008fa:	7f07a523          	sw	a6,2026(a5) # ffffffffc02050e0 <nr_free>
ffffffffc02008fe:	0141                	addi	sp,sp,16
ffffffffc0200900:	8082                	ret
        manager_base = base;
ffffffffc0200902:	00004797          	auipc	a5,0x4
ffffffffc0200906:	7ea7b723          	sd	a0,2030(a5) # ffffffffc02050f0 <manager_base>
        manager_n = n;
ffffffffc020090a:	00004797          	auipc	a5,0x4
ffffffffc020090e:	7cb7bf23          	sd	a1,2014(a5) # ffffffffc02050e8 <manager_n>
ffffffffc0200912:	bfa5                	j	ffffffffc020088a <buddy_init_memmap+0x3a>
        assert(PageReserved(p));
ffffffffc0200914:	00001697          	auipc	a3,0x1
ffffffffc0200918:	ba468693          	addi	a3,a3,-1116 # ffffffffc02014b8 <etext+0x2bc>
ffffffffc020091c:	00001617          	auipc	a2,0x1
ffffffffc0200920:	b3460613          	addi	a2,a2,-1228 # ffffffffc0201450 <etext+0x254>
ffffffffc0200924:	03300593          	li	a1,51
ffffffffc0200928:	00001517          	auipc	a0,0x1
ffffffffc020092c:	b4050513          	addi	a0,a0,-1216 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200930:	899ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200934:	00001697          	auipc	a3,0x1
ffffffffc0200938:	b1468693          	addi	a3,a3,-1260 # ffffffffc0201448 <etext+0x24c>
ffffffffc020093c:	00001617          	auipc	a2,0x1
ffffffffc0200940:	b1460613          	addi	a2,a2,-1260 # ffffffffc0201450 <etext+0x254>
ffffffffc0200944:	03000593          	li	a1,48
ffffffffc0200948:	00001517          	auipc	a0,0x1
ffffffffc020094c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200950:	879ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200954 <buddy_check>:
    free_page(p1);
    free_page(p2);
}

static void
buddy_check(void) {
ffffffffc0200954:	1101                	addi	sp,sp,-32
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200956:	4505                	li	a0,1
buddy_check(void) {
ffffffffc0200958:	ec06                	sd	ra,24(sp)
ffffffffc020095a:	e822                	sd	s0,16(sp)
ffffffffc020095c:	e426                	sd	s1,8(sp)
ffffffffc020095e:	e04a                	sd	s2,0(sp)
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200960:	228000ef          	jal	ffffffffc0200b88 <alloc_pages>
ffffffffc0200964:	16050263          	beqz	a0,ffffffffc0200ac8 <buddy_check+0x174>
ffffffffc0200968:	842a                	mv	s0,a0
    assert((p1 = alloc_page()) != NULL);
ffffffffc020096a:	4505                	li	a0,1
ffffffffc020096c:	21c000ef          	jal	ffffffffc0200b88 <alloc_pages>
ffffffffc0200970:	892a                	mv	s2,a0
ffffffffc0200972:	1e050b63          	beqz	a0,ffffffffc0200b68 <buddy_check+0x214>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200976:	4505                	li	a0,1
ffffffffc0200978:	210000ef          	jal	ffffffffc0200b88 <alloc_pages>
ffffffffc020097c:	84aa                	mv	s1,a0
ffffffffc020097e:	16050563          	beqz	a0,ffffffffc0200ae8 <buddy_check+0x194>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200982:	40a407b3          	sub	a5,s0,a0
ffffffffc0200986:	40a90733          	sub	a4,s2,a0
ffffffffc020098a:	0017b793          	seqz	a5,a5
ffffffffc020098e:	00173713          	seqz	a4,a4
ffffffffc0200992:	8fd9                	or	a5,a5,a4
ffffffffc0200994:	ebf1                	bnez	a5,ffffffffc0200a68 <buddy_check+0x114>
ffffffffc0200996:	0d240963          	beq	s0,s2,ffffffffc0200a68 <buddy_check+0x114>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020099a:	401c                	lw	a5,0(s0)
ffffffffc020099c:	e7d5                	bnez	a5,ffffffffc0200a48 <buddy_check+0xf4>
ffffffffc020099e:	00092783          	lw	a5,0(s2)
ffffffffc02009a2:	e3dd                	bnez	a5,ffffffffc0200a48 <buddy_check+0xf4>
ffffffffc02009a4:	411c                	lw	a5,0(a0)
ffffffffc02009a6:	e3cd                	bnez	a5,ffffffffc0200a48 <buddy_check+0xf4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009a8:	00004797          	auipc	a5,0x4
ffffffffc02009ac:	7787b783          	ld	a5,1912(a5) # ffffffffc0205120 <pages>
ffffffffc02009b0:	ccccd737          	lui	a4,0xccccd
ffffffffc02009b4:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac7ba5>
ffffffffc02009b8:	02071613          	slli	a2,a4,0x20
ffffffffc02009bc:	963a                	add	a2,a2,a4
ffffffffc02009be:	40f40733          	sub	a4,s0,a5
ffffffffc02009c2:	870d                	srai	a4,a4,0x3
ffffffffc02009c4:	02c70733          	mul	a4,a4,a2
ffffffffc02009c8:	00001597          	auipc	a1,0x1
ffffffffc02009cc:	0585b583          	ld	a1,88(a1) # ffffffffc0201a20 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009d0:	00004697          	auipc	a3,0x4
ffffffffc02009d4:	7486b683          	ld	a3,1864(a3) # ffffffffc0205118 <npage>
ffffffffc02009d8:	06b2                	slli	a3,a3,0xc
ffffffffc02009da:	972e                	add	a4,a4,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02009dc:	0732                	slli	a4,a4,0xc
ffffffffc02009de:	0cd77563          	bgeu	a4,a3,ffffffffc0200aa8 <buddy_check+0x154>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009e2:	40f90733          	sub	a4,s2,a5
ffffffffc02009e6:	870d                	srai	a4,a4,0x3
ffffffffc02009e8:	02c70733          	mul	a4,a4,a2
ffffffffc02009ec:	972e                	add	a4,a4,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02009ee:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009f0:	14d77c63          	bgeu	a4,a3,ffffffffc0200b48 <buddy_check+0x1f4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009f4:	ccccd737          	lui	a4,0xccccd
ffffffffc02009f8:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac7ba5>
ffffffffc02009fc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a00:	02071613          	slli	a2,a4,0x20
ffffffffc0200a04:	878d                	srai	a5,a5,0x3
ffffffffc0200a06:	9732                	add	a4,a4,a2
ffffffffc0200a08:	02e787b3          	mul	a5,a5,a4
ffffffffc0200a0c:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a0e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a10:	10d7fc63          	bgeu	a5,a3,ffffffffc0200b28 <buddy_check+0x1d4>
    free_page(p0);
ffffffffc0200a14:	8522                	mv	a0,s0
ffffffffc0200a16:	4585                	li	a1,1
ffffffffc0200a18:	17c000ef          	jal	ffffffffc0200b94 <free_pages>
    free_page(p1);
ffffffffc0200a1c:	854a                	mv	a0,s2
ffffffffc0200a1e:	4585                	li	a1,1
ffffffffc0200a20:	174000ef          	jal	ffffffffc0200b94 <free_pages>
    free_page(p2);
ffffffffc0200a24:	8526                	mv	a0,s1
ffffffffc0200a26:	4585                	li	a1,1
ffffffffc0200a28:	16c000ef          	jal	ffffffffc0200b94 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5);
ffffffffc0200a2c:	4515                	li	a0,5
ffffffffc0200a2e:	15a000ef          	jal	ffffffffc0200b88 <alloc_pages>
    assert(p0 != NULL);
ffffffffc0200a32:	c979                	beqz	a0,ffffffffc0200b08 <buddy_check+0x1b4>
    assert(!PageProperty(p0));
ffffffffc0200a34:	651c                	ld	a5,8(a0)
ffffffffc0200a36:	8b89                	andi	a5,a5,2
ffffffffc0200a38:	eba1                	bnez	a5,ffffffffc0200a88 <buddy_check+0x134>

    free_pages(p0, 5);

}
ffffffffc0200a3a:	6442                	ld	s0,16(sp)
ffffffffc0200a3c:	60e2                	ld	ra,24(sp)
ffffffffc0200a3e:	64a2                	ld	s1,8(sp)
ffffffffc0200a40:	6902                	ld	s2,0(sp)
    free_pages(p0, 5);
ffffffffc0200a42:	4595                	li	a1,5
}
ffffffffc0200a44:	6105                	addi	sp,sp,32
    free_pages(p0, 5);
ffffffffc0200a46:	a2b9                	j	ffffffffc0200b94 <free_pages>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200a48:	00001697          	auipc	a3,0x1
ffffffffc0200a4c:	b0868693          	addi	a3,a3,-1272 # ffffffffc0201550 <etext+0x354>
ffffffffc0200a50:	00001617          	auipc	a2,0x1
ffffffffc0200a54:	a0060613          	addi	a2,a2,-1536 # ffffffffc0201450 <etext+0x254>
ffffffffc0200a58:	0cb00593          	li	a1,203
ffffffffc0200a5c:	00001517          	auipc	a0,0x1
ffffffffc0200a60:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200a64:	f64ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a68:	00001697          	auipc	a3,0x1
ffffffffc0200a6c:	ac068693          	addi	a3,a3,-1344 # ffffffffc0201528 <etext+0x32c>
ffffffffc0200a70:	00001617          	auipc	a2,0x1
ffffffffc0200a74:	9e060613          	addi	a2,a2,-1568 # ffffffffc0201450 <etext+0x254>
ffffffffc0200a78:	0ca00593          	li	a1,202
ffffffffc0200a7c:	00001517          	auipc	a0,0x1
ffffffffc0200a80:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200a84:	f44ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200a88:	00001697          	auipc	a3,0x1
ffffffffc0200a8c:	b7868693          	addi	a3,a3,-1160 # ffffffffc0201600 <etext+0x404>
ffffffffc0200a90:	00001617          	auipc	a2,0x1
ffffffffc0200a94:	9c060613          	addi	a2,a2,-1600 # ffffffffc0201450 <etext+0x254>
ffffffffc0200a98:	0dd00593          	li	a1,221
ffffffffc0200a9c:	00001517          	auipc	a0,0x1
ffffffffc0200aa0:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200aa4:	f24ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200aa8:	00001697          	auipc	a3,0x1
ffffffffc0200aac:	ae868693          	addi	a3,a3,-1304 # ffffffffc0201590 <etext+0x394>
ffffffffc0200ab0:	00001617          	auipc	a2,0x1
ffffffffc0200ab4:	9a060613          	addi	a2,a2,-1632 # ffffffffc0201450 <etext+0x254>
ffffffffc0200ab8:	0cd00593          	li	a1,205
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200ac4:	f04ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ac8:	00001697          	auipc	a3,0x1
ffffffffc0200acc:	a0068693          	addi	a3,a3,-1536 # ffffffffc02014c8 <etext+0x2cc>
ffffffffc0200ad0:	00001617          	auipc	a2,0x1
ffffffffc0200ad4:	98060613          	addi	a2,a2,-1664 # ffffffffc0201450 <etext+0x254>
ffffffffc0200ad8:	0c600593          	li	a1,198
ffffffffc0200adc:	00001517          	auipc	a0,0x1
ffffffffc0200ae0:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200ae4:	ee4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ae8:	00001697          	auipc	a3,0x1
ffffffffc0200aec:	a2068693          	addi	a3,a3,-1504 # ffffffffc0201508 <etext+0x30c>
ffffffffc0200af0:	00001617          	auipc	a2,0x1
ffffffffc0200af4:	96060613          	addi	a2,a2,-1696 # ffffffffc0201450 <etext+0x254>
ffffffffc0200af8:	0c800593          	li	a1,200
ffffffffc0200afc:	00001517          	auipc	a0,0x1
ffffffffc0200b00:	96c50513          	addi	a0,a0,-1684 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200b04:	ec4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200b08:	00001697          	auipc	a3,0x1
ffffffffc0200b0c:	ae868693          	addi	a3,a3,-1304 # ffffffffc02015f0 <etext+0x3f4>
ffffffffc0200b10:	00001617          	auipc	a2,0x1
ffffffffc0200b14:	94060613          	addi	a2,a2,-1728 # ffffffffc0201450 <etext+0x254>
ffffffffc0200b18:	0dc00593          	li	a1,220
ffffffffc0200b1c:	00001517          	auipc	a0,0x1
ffffffffc0200b20:	94c50513          	addi	a0,a0,-1716 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200b24:	ea4ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b28:	00001697          	auipc	a3,0x1
ffffffffc0200b2c:	aa868693          	addi	a3,a3,-1368 # ffffffffc02015d0 <etext+0x3d4>
ffffffffc0200b30:	00001617          	auipc	a2,0x1
ffffffffc0200b34:	92060613          	addi	a2,a2,-1760 # ffffffffc0201450 <etext+0x254>
ffffffffc0200b38:	0cf00593          	li	a1,207
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	92c50513          	addi	a0,a0,-1748 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200b44:	e84ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b48:	00001697          	auipc	a3,0x1
ffffffffc0200b4c:	a6868693          	addi	a3,a3,-1432 # ffffffffc02015b0 <etext+0x3b4>
ffffffffc0200b50:	00001617          	auipc	a2,0x1
ffffffffc0200b54:	90060613          	addi	a2,a2,-1792 # ffffffffc0201450 <etext+0x254>
ffffffffc0200b58:	0ce00593          	li	a1,206
ffffffffc0200b5c:	00001517          	auipc	a0,0x1
ffffffffc0200b60:	90c50513          	addi	a0,a0,-1780 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200b64:	e64ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b68:	00001697          	auipc	a3,0x1
ffffffffc0200b6c:	98068693          	addi	a3,a3,-1664 # ffffffffc02014e8 <etext+0x2ec>
ffffffffc0200b70:	00001617          	auipc	a2,0x1
ffffffffc0200b74:	8e060613          	addi	a2,a2,-1824 # ffffffffc0201450 <etext+0x254>
ffffffffc0200b78:	0c700593          	li	a1,199
ffffffffc0200b7c:	00001517          	auipc	a0,0x1
ffffffffc0200b80:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0201468 <etext+0x26c>
ffffffffc0200b84:	e44ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200b88 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200b88:	00004797          	auipc	a5,0x4
ffffffffc0200b8c:	5707b783          	ld	a5,1392(a5) # ffffffffc02050f8 <pmm_manager>
ffffffffc0200b90:	6f9c                	ld	a5,24(a5)
ffffffffc0200b92:	8782                	jr	a5

ffffffffc0200b94 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200b94:	00004797          	auipc	a5,0x4
ffffffffc0200b98:	5647b783          	ld	a5,1380(a5) # ffffffffc02050f8 <pmm_manager>
ffffffffc0200b9c:	739c                	ld	a5,32(a5)
ffffffffc0200b9e:	8782                	jr	a5

ffffffffc0200ba0 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200ba0:	00001797          	auipc	a5,0x1
ffffffffc0200ba4:	cb878793          	addi	a5,a5,-840 # ffffffffc0201858 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ba8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200baa:	7139                	addi	sp,sp,-64
ffffffffc0200bac:	fc06                	sd	ra,56(sp)
ffffffffc0200bae:	f822                	sd	s0,48(sp)
ffffffffc0200bb0:	f426                	sd	s1,40(sp)
ffffffffc0200bb2:	ec4e                	sd	s3,24(sp)
ffffffffc0200bb4:	f04a                	sd	s2,32(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200bb6:	00004417          	auipc	s0,0x4
ffffffffc0200bba:	54240413          	addi	s0,s0,1346 # ffffffffc02050f8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0201638 <etext+0x43c>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200bc6:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200bc8:	d80ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0200bcc:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200bce:	00004497          	auipc	s1,0x4
ffffffffc0200bd2:	54248493          	addi	s1,s1,1346 # ffffffffc0205110 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200bd6:	679c                	ld	a5,8(a5)
ffffffffc0200bd8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200bda:	57f5                	li	a5,-3
ffffffffc0200bdc:	07fa                	slli	a5,a5,0x1e
ffffffffc0200bde:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200be0:	97bff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc0200be4:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200be6:	97fff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200bea:	14050c63          	beqz	a0,ffffffffc0200d42 <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200bee:	00a98933          	add	s2,s3,a0
ffffffffc0200bf2:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc0200bf4:	00001517          	auipc	a0,0x1
ffffffffc0200bf8:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0201680 <etext+0x484>
ffffffffc0200bfc:	d4cff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200c00:	65a2                	ld	a1,8(sp)
ffffffffc0200c02:	864e                	mv	a2,s3
ffffffffc0200c04:	fff90693          	addi	a3,s2,-1
ffffffffc0200c08:	00001517          	auipc	a0,0x1
ffffffffc0200c0c:	a9050513          	addi	a0,a0,-1392 # ffffffffc0201698 <etext+0x49c>
ffffffffc0200c10:	d38ff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200c14:	c80007b7          	lui	a5,0xc8000
ffffffffc0200c18:	85ca                	mv	a1,s2
ffffffffc0200c1a:	0d27e263          	bltu	a5,s2,ffffffffc0200cde <pmm_init+0x13e>
ffffffffc0200c1e:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200c20:	00005697          	auipc	a3,0x5
ffffffffc0200c24:	50768693          	addi	a3,a3,1287 # ffffffffc0206127 <end+0xfff>
ffffffffc0200c28:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0200c2a:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200c2c:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc0200c30:	00004797          	auipc	a5,0x4
ffffffffc0200c34:	4eb7b423          	sd	a1,1256(a5) # ffffffffc0205118 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200c38:	00004797          	auipc	a5,0x4
ffffffffc0200c3c:	4ed7b423          	sd	a3,1256(a5) # ffffffffc0205120 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200c40:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200c42:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200c44:	02080963          	beqz	a6,ffffffffc0200c76 <pmm_init+0xd6>
ffffffffc0200c48:	00259613          	slli	a2,a1,0x2
ffffffffc0200c4c:	962e                	add	a2,a2,a1
ffffffffc0200c4e:	fec007b7          	lui	a5,0xfec00
ffffffffc0200c52:	97b6                	add	a5,a5,a3
ffffffffc0200c54:	060e                	slli	a2,a2,0x3
ffffffffc0200c56:	963e                	add	a2,a2,a5
ffffffffc0200c58:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200c5a:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200c5c:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9faf00>
        SetPageReserved(pages + i);
ffffffffc0200c60:	00176713          	ori	a4,a4,1
ffffffffc0200c64:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200c68:	fec799e3          	bne	a5,a2,ffffffffc0200c5a <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200c6c:	00281793          	slli	a5,a6,0x2
ffffffffc0200c70:	97c2                	add	a5,a5,a6
ffffffffc0200c72:	078e                	slli	a5,a5,0x3
ffffffffc0200c74:	96be                	add	a3,a3,a5
ffffffffc0200c76:	c02007b7          	lui	a5,0xc0200
ffffffffc0200c7a:	0af6e863          	bltu	a3,a5,ffffffffc0200d2a <pmm_init+0x18a>
ffffffffc0200c7e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200c80:	77fd                	lui	a5,0xfffff
ffffffffc0200c82:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200c86:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200c88:	0526ed63          	bltu	a3,s2,ffffffffc0200ce2 <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200c8c:	601c                	ld	a5,0(s0)
ffffffffc0200c8e:	7b9c                	ld	a5,48(a5)
ffffffffc0200c90:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200c92:	00001517          	auipc	a0,0x1
ffffffffc0200c96:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201720 <etext+0x524>
ffffffffc0200c9a:	caeff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200c9e:	00003597          	auipc	a1,0x3
ffffffffc0200ca2:	36258593          	addi	a1,a1,866 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200ca6:	00004797          	auipc	a5,0x4
ffffffffc0200caa:	46b7b123          	sd	a1,1122(a5) # ffffffffc0205108 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200cae:	c02007b7          	lui	a5,0xc0200
ffffffffc0200cb2:	0af5e463          	bltu	a1,a5,ffffffffc0200d5a <pmm_init+0x1ba>
ffffffffc0200cb6:	609c                	ld	a5,0(s1)
}
ffffffffc0200cb8:	7442                	ld	s0,48(sp)
ffffffffc0200cba:	70e2                	ld	ra,56(sp)
ffffffffc0200cbc:	74a2                	ld	s1,40(sp)
ffffffffc0200cbe:	7902                	ld	s2,32(sp)
ffffffffc0200cc0:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200cc2:	40f586b3          	sub	a3,a1,a5
ffffffffc0200cc6:	00004797          	auipc	a5,0x4
ffffffffc0200cca:	42d7bd23          	sd	a3,1082(a5) # ffffffffc0205100 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200cce:	00001517          	auipc	a0,0x1
ffffffffc0200cd2:	a7250513          	addi	a0,a0,-1422 # ffffffffc0201740 <etext+0x544>
ffffffffc0200cd6:	8636                	mv	a2,a3
}
ffffffffc0200cd8:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200cda:	c6eff06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200cde:	85be                	mv	a1,a5
ffffffffc0200ce0:	bf3d                	j	ffffffffc0200c1e <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200ce2:	6705                	lui	a4,0x1
ffffffffc0200ce4:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0200ce6:	96ba                	add	a3,a3,a4
ffffffffc0200ce8:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200cea:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200cee:	02b7f263          	bgeu	a5,a1,ffffffffc0200d12 <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc0200cf2:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200cf4:	fff80637          	lui	a2,0xfff80
ffffffffc0200cf8:	97b2                	add	a5,a5,a2
ffffffffc0200cfa:	00279513          	slli	a0,a5,0x2
ffffffffc0200cfe:	953e                	add	a0,a0,a5
ffffffffc0200d00:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200d02:	40d90933          	sub	s2,s2,a3
ffffffffc0200d06:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200d08:	00c95593          	srli	a1,s2,0xc
ffffffffc0200d0c:	9546                	add	a0,a0,a7
ffffffffc0200d0e:	9782                	jalr	a5
}
ffffffffc0200d10:	bfb5                	j	ffffffffc0200c8c <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	9de60613          	addi	a2,a2,-1570 # ffffffffc02016f0 <etext+0x4f4>
ffffffffc0200d1a:	06a00593          	li	a1,106
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	9f250513          	addi	a0,a0,-1550 # ffffffffc0201710 <etext+0x514>
ffffffffc0200d26:	ca2ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d2a:	00001617          	auipc	a2,0x1
ffffffffc0200d2e:	99e60613          	addi	a2,a2,-1634 # ffffffffc02016c8 <etext+0x4cc>
ffffffffc0200d32:	06100593          	li	a1,97
ffffffffc0200d36:	00001517          	auipc	a0,0x1
ffffffffc0200d3a:	93a50513          	addi	a0,a0,-1734 # ffffffffc0201670 <etext+0x474>
ffffffffc0200d3e:	c8aff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc0200d42:	00001617          	auipc	a2,0x1
ffffffffc0200d46:	90e60613          	addi	a2,a2,-1778 # ffffffffc0201650 <etext+0x454>
ffffffffc0200d4a:	04900593          	li	a1,73
ffffffffc0200d4e:	00001517          	auipc	a0,0x1
ffffffffc0200d52:	92250513          	addi	a0,a0,-1758 # ffffffffc0201670 <etext+0x474>
ffffffffc0200d56:	c72ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d5a:	86ae                	mv	a3,a1
ffffffffc0200d5c:	00001617          	auipc	a2,0x1
ffffffffc0200d60:	96c60613          	addi	a2,a2,-1684 # ffffffffc02016c8 <etext+0x4cc>
ffffffffc0200d64:	07c00593          	li	a1,124
ffffffffc0200d68:	00001517          	auipc	a0,0x1
ffffffffc0200d6c:	90850513          	addi	a0,a0,-1784 # ffffffffc0201670 <etext+0x474>
ffffffffc0200d70:	c58ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d74 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200d74:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200d76:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200d7a:	f022                	sd	s0,32(sp)
ffffffffc0200d7c:	ec26                	sd	s1,24(sp)
ffffffffc0200d7e:	e84a                	sd	s2,16(sp)
ffffffffc0200d80:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200d82:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200d86:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200d88:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200d8c:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200d90:	84aa                	mv	s1,a0
ffffffffc0200d92:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0200d94:	03067d63          	bgeu	a2,a6,ffffffffc0200dce <printnum+0x5a>
ffffffffc0200d98:	e44e                	sd	s3,8(sp)
ffffffffc0200d9a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200d9c:	4785                	li	a5,1
ffffffffc0200d9e:	00e7d763          	bge	a5,a4,ffffffffc0200dac <printnum+0x38>
            putch(padc, putdat);
ffffffffc0200da2:	85ca                	mv	a1,s2
ffffffffc0200da4:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0200da6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200da8:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200daa:	fc65                	bnez	s0,ffffffffc0200da2 <printnum+0x2e>
ffffffffc0200dac:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200dae:	00001797          	auipc	a5,0x1
ffffffffc0200db2:	9d278793          	addi	a5,a5,-1582 # ffffffffc0201780 <etext+0x584>
ffffffffc0200db6:	97d2                	add	a5,a5,s4
}
ffffffffc0200db8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200dba:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0200dbe:	70a2                	ld	ra,40(sp)
ffffffffc0200dc0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200dc2:	85ca                	mv	a1,s2
ffffffffc0200dc4:	87a6                	mv	a5,s1
}
ffffffffc0200dc6:	6942                	ld	s2,16(sp)
ffffffffc0200dc8:	64e2                	ld	s1,24(sp)
ffffffffc0200dca:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200dcc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200dce:	03065633          	divu	a2,a2,a6
ffffffffc0200dd2:	8722                	mv	a4,s0
ffffffffc0200dd4:	fa1ff0ef          	jal	ffffffffc0200d74 <printnum>
ffffffffc0200dd8:	bfd9                	j	ffffffffc0200dae <printnum+0x3a>

ffffffffc0200dda <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200dda:	7119                	addi	sp,sp,-128
ffffffffc0200ddc:	f4a6                	sd	s1,104(sp)
ffffffffc0200dde:	f0ca                	sd	s2,96(sp)
ffffffffc0200de0:	ecce                	sd	s3,88(sp)
ffffffffc0200de2:	e8d2                	sd	s4,80(sp)
ffffffffc0200de4:	e4d6                	sd	s5,72(sp)
ffffffffc0200de6:	e0da                	sd	s6,64(sp)
ffffffffc0200de8:	f862                	sd	s8,48(sp)
ffffffffc0200dea:	fc86                	sd	ra,120(sp)
ffffffffc0200dec:	f8a2                	sd	s0,112(sp)
ffffffffc0200dee:	fc5e                	sd	s7,56(sp)
ffffffffc0200df0:	f466                	sd	s9,40(sp)
ffffffffc0200df2:	f06a                	sd	s10,32(sp)
ffffffffc0200df4:	ec6e                	sd	s11,24(sp)
ffffffffc0200df6:	84aa                	mv	s1,a0
ffffffffc0200df8:	8c32                	mv	s8,a2
ffffffffc0200dfa:	8a36                	mv	s4,a3
ffffffffc0200dfc:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200dfe:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200e02:	05500b13          	li	s6,85
ffffffffc0200e06:	00001a97          	auipc	s5,0x1
ffffffffc0200e0a:	a8aa8a93          	addi	s5,s5,-1398 # ffffffffc0201890 <buddy_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e0e:	000c4503          	lbu	a0,0(s8)
ffffffffc0200e12:	001c0413          	addi	s0,s8,1
ffffffffc0200e16:	01350a63          	beq	a0,s3,ffffffffc0200e2a <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0200e1a:	cd0d                	beqz	a0,ffffffffc0200e54 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0200e1c:	85ca                	mv	a1,s2
ffffffffc0200e1e:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e20:	00044503          	lbu	a0,0(s0)
ffffffffc0200e24:	0405                	addi	s0,s0,1
ffffffffc0200e26:	ff351ae3          	bne	a0,s3,ffffffffc0200e1a <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0200e2a:	5cfd                	li	s9,-1
ffffffffc0200e2c:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0200e2e:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0200e32:	4b81                	li	s7,0
ffffffffc0200e34:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200e36:	00044683          	lbu	a3,0(s0)
ffffffffc0200e3a:	00140c13          	addi	s8,s0,1
ffffffffc0200e3e:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0200e42:	0ff5f593          	zext.b	a1,a1
ffffffffc0200e46:	02bb6663          	bltu	s6,a1,ffffffffc0200e72 <vprintfmt+0x98>
ffffffffc0200e4a:	058a                	slli	a1,a1,0x2
ffffffffc0200e4c:	95d6                	add	a1,a1,s5
ffffffffc0200e4e:	4198                	lw	a4,0(a1)
ffffffffc0200e50:	9756                	add	a4,a4,s5
ffffffffc0200e52:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0200e54:	70e6                	ld	ra,120(sp)
ffffffffc0200e56:	7446                	ld	s0,112(sp)
ffffffffc0200e58:	74a6                	ld	s1,104(sp)
ffffffffc0200e5a:	7906                	ld	s2,96(sp)
ffffffffc0200e5c:	69e6                	ld	s3,88(sp)
ffffffffc0200e5e:	6a46                	ld	s4,80(sp)
ffffffffc0200e60:	6aa6                	ld	s5,72(sp)
ffffffffc0200e62:	6b06                	ld	s6,64(sp)
ffffffffc0200e64:	7be2                	ld	s7,56(sp)
ffffffffc0200e66:	7c42                	ld	s8,48(sp)
ffffffffc0200e68:	7ca2                	ld	s9,40(sp)
ffffffffc0200e6a:	7d02                	ld	s10,32(sp)
ffffffffc0200e6c:	6de2                	ld	s11,24(sp)
ffffffffc0200e6e:	6109                	addi	sp,sp,128
ffffffffc0200e70:	8082                	ret
            putch('%', putdat);
ffffffffc0200e72:	85ca                	mv	a1,s2
ffffffffc0200e74:	02500513          	li	a0,37
ffffffffc0200e78:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0200e7a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0200e7e:	02500713          	li	a4,37
ffffffffc0200e82:	8c22                	mv	s8,s0
ffffffffc0200e84:	f8e785e3          	beq	a5,a4,ffffffffc0200e0e <vprintfmt+0x34>
ffffffffc0200e88:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0200e8c:	1c7d                	addi	s8,s8,-1
ffffffffc0200e8e:	fee79de3          	bne	a5,a4,ffffffffc0200e88 <vprintfmt+0xae>
ffffffffc0200e92:	bfb5                	j	ffffffffc0200e0e <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0200e94:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0200e98:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0200e9a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0200e9e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0200ea2:	24e56a63          	bltu	a0,a4,ffffffffc02010f6 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0200ea6:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ea8:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0200eaa:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0200eae:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0200eb2:	0197073b          	addw	a4,a4,s9
ffffffffc0200eb6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200eba:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200ebc:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0200ec0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0200ec2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0200ec6:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0200eca:	feb570e3          	bgeu	a0,a1,ffffffffc0200eaa <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0200ece:	f60d54e3          	bgez	s10,ffffffffc0200e36 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0200ed2:	8d66                	mv	s10,s9
ffffffffc0200ed4:	5cfd                	li	s9,-1
ffffffffc0200ed6:	b785                	j	ffffffffc0200e36 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ed8:	8db6                	mv	s11,a3
ffffffffc0200eda:	8462                	mv	s0,s8
ffffffffc0200edc:	bfa9                	j	ffffffffc0200e36 <vprintfmt+0x5c>
ffffffffc0200ede:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0200ee0:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0200ee2:	bf91                	j	ffffffffc0200e36 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0200ee4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200ee6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200eea:	00f74463          	blt	a4,a5,ffffffffc0200ef2 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0200eee:	1a078763          	beqz	a5,ffffffffc020109c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0200ef2:	000a3603          	ld	a2,0(s4)
ffffffffc0200ef6:	46c1                	li	a3,16
ffffffffc0200ef8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0200efa:	000d879b          	sext.w	a5,s11
ffffffffc0200efe:	876a                	mv	a4,s10
ffffffffc0200f00:	85ca                	mv	a1,s2
ffffffffc0200f02:	8526                	mv	a0,s1
ffffffffc0200f04:	e71ff0ef          	jal	ffffffffc0200d74 <printnum>
            break;
ffffffffc0200f08:	b719                	j	ffffffffc0200e0e <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0200f0a:	000a2503          	lw	a0,0(s4)
ffffffffc0200f0e:	85ca                	mv	a1,s2
ffffffffc0200f10:	0a21                	addi	s4,s4,8
ffffffffc0200f12:	9482                	jalr	s1
            break;
ffffffffc0200f14:	bded                	j	ffffffffc0200e0e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0200f16:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200f18:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200f1c:	00f74463          	blt	a4,a5,ffffffffc0200f24 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0200f20:	16078963          	beqz	a5,ffffffffc0201092 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0200f24:	000a3603          	ld	a2,0(s4)
ffffffffc0200f28:	46a9                	li	a3,10
ffffffffc0200f2a:	8a2e                	mv	s4,a1
ffffffffc0200f2c:	b7f9                	j	ffffffffc0200efa <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0200f2e:	85ca                	mv	a1,s2
ffffffffc0200f30:	03000513          	li	a0,48
ffffffffc0200f34:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0200f36:	85ca                	mv	a1,s2
ffffffffc0200f38:	07800513          	li	a0,120
ffffffffc0200f3c:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200f3e:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0200f42:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200f44:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0200f46:	bf55                	j	ffffffffc0200efa <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0200f48:	85ca                	mv	a1,s2
ffffffffc0200f4a:	02500513          	li	a0,37
ffffffffc0200f4e:	9482                	jalr	s1
            break;
ffffffffc0200f50:	bd7d                	j	ffffffffc0200e0e <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0200f52:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f56:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0200f58:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0200f5a:	bf95                	j	ffffffffc0200ece <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0200f5c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200f5e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200f62:	00f74463          	blt	a4,a5,ffffffffc0200f6a <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0200f66:	12078163          	beqz	a5,ffffffffc0201088 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0200f6a:	000a3603          	ld	a2,0(s4)
ffffffffc0200f6e:	46a1                	li	a3,8
ffffffffc0200f70:	8a2e                	mv	s4,a1
ffffffffc0200f72:	b761                	j	ffffffffc0200efa <vprintfmt+0x120>
            if (width < 0)
ffffffffc0200f74:	876a                	mv	a4,s10
ffffffffc0200f76:	000d5363          	bgez	s10,ffffffffc0200f7c <vprintfmt+0x1a2>
ffffffffc0200f7a:	4701                	li	a4,0
ffffffffc0200f7c:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f80:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0200f82:	bd55                	j	ffffffffc0200e36 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0200f84:	000d841b          	sext.w	s0,s11
ffffffffc0200f88:	fd340793          	addi	a5,s0,-45
ffffffffc0200f8c:	00f037b3          	snez	a5,a5
ffffffffc0200f90:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200f94:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0200f98:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200f9a:	008a0793          	addi	a5,s4,8
ffffffffc0200f9e:	e43e                	sd	a5,8(sp)
ffffffffc0200fa0:	100d8c63          	beqz	s11,ffffffffc02010b8 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0200fa4:	12071363          	bnez	a4,ffffffffc02010ca <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200fa8:	000dc783          	lbu	a5,0(s11)
ffffffffc0200fac:	0007851b          	sext.w	a0,a5
ffffffffc0200fb0:	c78d                	beqz	a5,ffffffffc0200fda <vprintfmt+0x200>
ffffffffc0200fb2:	0d85                	addi	s11,s11,1
ffffffffc0200fb4:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200fb6:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200fba:	000cc563          	bltz	s9,ffffffffc0200fc4 <vprintfmt+0x1ea>
ffffffffc0200fbe:	3cfd                	addiw	s9,s9,-1
ffffffffc0200fc0:	008c8d63          	beq	s9,s0,ffffffffc0200fda <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200fc4:	020b9663          	bnez	s7,ffffffffc0200ff0 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0200fc8:	85ca                	mv	a1,s2
ffffffffc0200fca:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200fcc:	000dc783          	lbu	a5,0(s11)
ffffffffc0200fd0:	0d85                	addi	s11,s11,1
ffffffffc0200fd2:	3d7d                	addiw	s10,s10,-1
ffffffffc0200fd4:	0007851b          	sext.w	a0,a5
ffffffffc0200fd8:	f3ed                	bnez	a5,ffffffffc0200fba <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0200fda:	01a05963          	blez	s10,ffffffffc0200fec <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0200fde:	85ca                	mv	a1,s2
ffffffffc0200fe0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0200fe4:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0200fe6:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0200fe8:	fe0d1be3          	bnez	s10,ffffffffc0200fde <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200fec:	6a22                	ld	s4,8(sp)
ffffffffc0200fee:	b505                	j	ffffffffc0200e0e <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0200ff0:	3781                	addiw	a5,a5,-32
ffffffffc0200ff2:	fcfa7be3          	bgeu	s4,a5,ffffffffc0200fc8 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0200ff6:	03f00513          	li	a0,63
ffffffffc0200ffa:	85ca                	mv	a1,s2
ffffffffc0200ffc:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0200ffe:	000dc783          	lbu	a5,0(s11)
ffffffffc0201002:	0d85                	addi	s11,s11,1
ffffffffc0201004:	3d7d                	addiw	s10,s10,-1
ffffffffc0201006:	0007851b          	sext.w	a0,a5
ffffffffc020100a:	dbe1                	beqz	a5,ffffffffc0200fda <vprintfmt+0x200>
ffffffffc020100c:	fa0cd9e3          	bgez	s9,ffffffffc0200fbe <vprintfmt+0x1e4>
ffffffffc0201010:	b7c5                	j	ffffffffc0200ff0 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0201012:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201016:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201018:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020101a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc020101e:	8fb9                	xor	a5,a5,a4
ffffffffc0201020:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201024:	02d64563          	blt	a2,a3,ffffffffc020104e <vprintfmt+0x274>
ffffffffc0201028:	00001797          	auipc	a5,0x1
ffffffffc020102c:	9c078793          	addi	a5,a5,-1600 # ffffffffc02019e8 <error_string>
ffffffffc0201030:	00369713          	slli	a4,a3,0x3
ffffffffc0201034:	97ba                	add	a5,a5,a4
ffffffffc0201036:	639c                	ld	a5,0(a5)
ffffffffc0201038:	cb99                	beqz	a5,ffffffffc020104e <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc020103a:	86be                	mv	a3,a5
ffffffffc020103c:	00000617          	auipc	a2,0x0
ffffffffc0201040:	77460613          	addi	a2,a2,1908 # ffffffffc02017b0 <etext+0x5b4>
ffffffffc0201044:	85ca                	mv	a1,s2
ffffffffc0201046:	8526                	mv	a0,s1
ffffffffc0201048:	0d8000ef          	jal	ffffffffc0201120 <printfmt>
ffffffffc020104c:	b3c9                	j	ffffffffc0200e0e <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020104e:	00000617          	auipc	a2,0x0
ffffffffc0201052:	75260613          	addi	a2,a2,1874 # ffffffffc02017a0 <etext+0x5a4>
ffffffffc0201056:	85ca                	mv	a1,s2
ffffffffc0201058:	8526                	mv	a0,s1
ffffffffc020105a:	0c6000ef          	jal	ffffffffc0201120 <printfmt>
ffffffffc020105e:	bb45                	j	ffffffffc0200e0e <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201060:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201062:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201066:	00f74363          	blt	a4,a5,ffffffffc020106c <vprintfmt+0x292>
    else if (lflag) {
ffffffffc020106a:	cf81                	beqz	a5,ffffffffc0201082 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc020106c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201070:	02044b63          	bltz	s0,ffffffffc02010a6 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201074:	8622                	mv	a2,s0
ffffffffc0201076:	8a5e                	mv	s4,s7
ffffffffc0201078:	46a9                	li	a3,10
ffffffffc020107a:	b541                	j	ffffffffc0200efa <vprintfmt+0x120>
            lflag ++;
ffffffffc020107c:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020107e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201080:	bb5d                	j	ffffffffc0200e36 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201082:	000a2403          	lw	s0,0(s4)
ffffffffc0201086:	b7ed                	j	ffffffffc0201070 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201088:	000a6603          	lwu	a2,0(s4)
ffffffffc020108c:	46a1                	li	a3,8
ffffffffc020108e:	8a2e                	mv	s4,a1
ffffffffc0201090:	b5ad                	j	ffffffffc0200efa <vprintfmt+0x120>
ffffffffc0201092:	000a6603          	lwu	a2,0(s4)
ffffffffc0201096:	46a9                	li	a3,10
ffffffffc0201098:	8a2e                	mv	s4,a1
ffffffffc020109a:	b585                	j	ffffffffc0200efa <vprintfmt+0x120>
ffffffffc020109c:	000a6603          	lwu	a2,0(s4)
ffffffffc02010a0:	46c1                	li	a3,16
ffffffffc02010a2:	8a2e                	mv	s4,a1
ffffffffc02010a4:	bd99                	j	ffffffffc0200efa <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02010a6:	85ca                	mv	a1,s2
ffffffffc02010a8:	02d00513          	li	a0,45
ffffffffc02010ac:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02010ae:	40800633          	neg	a2,s0
ffffffffc02010b2:	8a5e                	mv	s4,s7
ffffffffc02010b4:	46a9                	li	a3,10
ffffffffc02010b6:	b591                	j	ffffffffc0200efa <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02010b8:	e329                	bnez	a4,ffffffffc02010fa <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010ba:	02800793          	li	a5,40
ffffffffc02010be:	853e                	mv	a0,a5
ffffffffc02010c0:	00000d97          	auipc	s11,0x0
ffffffffc02010c4:	6d9d8d93          	addi	s11,s11,1753 # ffffffffc0201799 <etext+0x59d>
ffffffffc02010c8:	b5f5                	j	ffffffffc0200fb4 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010ca:	85e6                	mv	a1,s9
ffffffffc02010cc:	856e                	mv	a0,s11
ffffffffc02010ce:	0a4000ef          	jal	ffffffffc0201172 <strnlen>
ffffffffc02010d2:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02010d6:	01a05863          	blez	s10,ffffffffc02010e6 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02010da:	85ca                	mv	a1,s2
ffffffffc02010dc:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010de:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02010e0:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010e2:	fe0d1ce3          	bnez	s10,ffffffffc02010da <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010e6:	000dc783          	lbu	a5,0(s11)
ffffffffc02010ea:	0007851b          	sext.w	a0,a5
ffffffffc02010ee:	ec0792e3          	bnez	a5,ffffffffc0200fb2 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02010f2:	6a22                	ld	s4,8(sp)
ffffffffc02010f4:	bb29                	j	ffffffffc0200e0e <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02010f6:	8462                	mv	s0,s8
ffffffffc02010f8:	bbd9                	j	ffffffffc0200ece <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010fa:	85e6                	mv	a1,s9
ffffffffc02010fc:	00000517          	auipc	a0,0x0
ffffffffc0201100:	69c50513          	addi	a0,a0,1692 # ffffffffc0201798 <etext+0x59c>
ffffffffc0201104:	06e000ef          	jal	ffffffffc0201172 <strnlen>
ffffffffc0201108:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020110c:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0201110:	00000d97          	auipc	s11,0x0
ffffffffc0201114:	688d8d93          	addi	s11,s11,1672 # ffffffffc0201798 <etext+0x59c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201118:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020111a:	fda040e3          	bgtz	s10,ffffffffc02010da <vprintfmt+0x300>
ffffffffc020111e:	bd51                	j	ffffffffc0200fb2 <vprintfmt+0x1d8>

ffffffffc0201120 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201120:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201122:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201126:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201128:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020112a:	ec06                	sd	ra,24(sp)
ffffffffc020112c:	f83a                	sd	a4,48(sp)
ffffffffc020112e:	fc3e                	sd	a5,56(sp)
ffffffffc0201130:	e0c2                	sd	a6,64(sp)
ffffffffc0201132:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201134:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201136:	ca5ff0ef          	jal	ffffffffc0200dda <vprintfmt>
}
ffffffffc020113a:	60e2                	ld	ra,24(sp)
ffffffffc020113c:	6161                	addi	sp,sp,80
ffffffffc020113e:	8082                	ret

ffffffffc0201140 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201140:	00004717          	auipc	a4,0x4
ffffffffc0201144:	ed073703          	ld	a4,-304(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201148:	4781                	li	a5,0
ffffffffc020114a:	88ba                	mv	a7,a4
ffffffffc020114c:	852a                	mv	a0,a0
ffffffffc020114e:	85be                	mv	a1,a5
ffffffffc0201150:	863e                	mv	a2,a5
ffffffffc0201152:	00000073          	ecall
ffffffffc0201156:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201158:	8082                	ret

ffffffffc020115a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020115a:	00054783          	lbu	a5,0(a0)
ffffffffc020115e:	cb81                	beqz	a5,ffffffffc020116e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201160:	4781                	li	a5,0
        cnt ++;
ffffffffc0201162:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201164:	00f50733          	add	a4,a0,a5
ffffffffc0201168:	00074703          	lbu	a4,0(a4)
ffffffffc020116c:	fb7d                	bnez	a4,ffffffffc0201162 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020116e:	853e                	mv	a0,a5
ffffffffc0201170:	8082                	ret

ffffffffc0201172 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201172:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201174:	e589                	bnez	a1,ffffffffc020117e <strnlen+0xc>
ffffffffc0201176:	a811                	j	ffffffffc020118a <strnlen+0x18>
        cnt ++;
ffffffffc0201178:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020117a:	00f58863          	beq	a1,a5,ffffffffc020118a <strnlen+0x18>
ffffffffc020117e:	00f50733          	add	a4,a0,a5
ffffffffc0201182:	00074703          	lbu	a4,0(a4)
ffffffffc0201186:	fb6d                	bnez	a4,ffffffffc0201178 <strnlen+0x6>
ffffffffc0201188:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020118a:	852e                	mv	a0,a1
ffffffffc020118c:	8082                	ret

ffffffffc020118e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020118e:	00054783          	lbu	a5,0(a0)
ffffffffc0201192:	e791                	bnez	a5,ffffffffc020119e <strcmp+0x10>
ffffffffc0201194:	a01d                	j	ffffffffc02011ba <strcmp+0x2c>
ffffffffc0201196:	00054783          	lbu	a5,0(a0)
ffffffffc020119a:	cb99                	beqz	a5,ffffffffc02011b0 <strcmp+0x22>
ffffffffc020119c:	0585                	addi	a1,a1,1
ffffffffc020119e:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02011a2:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02011a4:	fef709e3          	beq	a4,a5,ffffffffc0201196 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02011a8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02011ac:	9d19                	subw	a0,a0,a4
ffffffffc02011ae:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02011b0:	0015c703          	lbu	a4,1(a1)
ffffffffc02011b4:	4501                	li	a0,0
}
ffffffffc02011b6:	9d19                	subw	a0,a0,a4
ffffffffc02011b8:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02011ba:	0005c703          	lbu	a4,0(a1)
ffffffffc02011be:	4501                	li	a0,0
ffffffffc02011c0:	b7f5                	j	ffffffffc02011ac <strcmp+0x1e>

ffffffffc02011c2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02011c2:	ce01                	beqz	a2,ffffffffc02011da <strncmp+0x18>
ffffffffc02011c4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02011c8:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02011ca:	cb91                	beqz	a5,ffffffffc02011de <strncmp+0x1c>
ffffffffc02011cc:	0005c703          	lbu	a4,0(a1)
ffffffffc02011d0:	00f71763          	bne	a4,a5,ffffffffc02011de <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02011d4:	0505                	addi	a0,a0,1
ffffffffc02011d6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02011d8:	f675                	bnez	a2,ffffffffc02011c4 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02011da:	4501                	li	a0,0
ffffffffc02011dc:	8082                	ret
ffffffffc02011de:	00054503          	lbu	a0,0(a0)
ffffffffc02011e2:	0005c783          	lbu	a5,0(a1)
ffffffffc02011e6:	9d1d                	subw	a0,a0,a5
}
ffffffffc02011e8:	8082                	ret

ffffffffc02011ea <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02011ea:	ca01                	beqz	a2,ffffffffc02011fa <memset+0x10>
ffffffffc02011ec:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02011ee:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02011f0:	0785                	addi	a5,a5,1
ffffffffc02011f2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02011f6:	fef61de3          	bne	a2,a5,ffffffffc02011f0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02011fa:	8082                	ret
