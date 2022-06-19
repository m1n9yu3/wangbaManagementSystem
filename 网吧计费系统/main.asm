.386
.model flat,stdcall
.stack 4096



include kernel32.inc
include user32.inc
include msvcrt.inc

includelib  kernel32.lib
includelib  user32.lib
includelib msvcrt.lib
.data


; 汇编中结构体声明
machineStatus struct
machineId dword	?
machineOn db ?
; 卡号
cardOrder DWORD ?
machineStatus ends

; 卡信息链表
cardInfoLinked struct
; 下一个链表
NextLink DWORD ?
; 卡号
cardOrder DWORD ?
; 卡密码
cardPass DWORD ?
; 卡余额
cardBalance DWORD ?

cardInfoLinked ends

; 机器号: eax
; 卡号: ebx
; 密码: ecx
; 余额: edx

; 历史记录链表
historyInfoLinked struct
; 下一个链表
NextLink DWORD ?
; 状态
machineOn DWORD ?
; 机器号
machineId dword	?
; 时间戳
time DWORD ?
; 卡号
cardOrder DWORD ?
historyInfoLinked ends

; 机器数组 两种状态 0, 1
machineAry machineStatus 16 dup(<>)
; 卡数组
cardInfoHeadLink cardInfoLinked <>
; 历史记录数组 
historyInfoHeadLinked historyInfoLinked <>

FORMAT_S db '%s',0,0
FORMAT_D db '%d',0,0


szCls db 'cls',0,0
szPause db 'pause',0,0
szMenu db '网吧计费管理系统',12,'1.上机操作',12,'2.下机操作',12,'3.注册新会员',12,'4.查看历史记录',12,'5.退出',12,'请输入你的选择',0,0

szMachineId db '机器号码:', 0,0
szFinalTime db '结束时间:',0,0
szOK db 10,12,'确认？Y/N',0,0
szCardId db '卡号:',0,0
szCardPass db '密码:',0,0
szStartTime db '开始时间:',0,0
szEndTime db '结束时间:',0,0

szCardPassOk db '确认密码:',0,0

szOnMachineSucessHint db '操作成功，开始计时...',12,0,0
szOperatorChanelHint db '操作取消',12,0,0

szDownMachineSucessHint db '总共时长%d分钟, 消费%d 元',12,0,0
szRegisterMemberHint db '恭喜你，注册成功，您的卡号是%s',12, 0,0
szTimeFormat db '%d-%d-%d %d:%d:%d',0,0

szHistoryFormat db '机器号: %s - 时间戳: %d- 卡号: %s-操作类型: %d',12,0,0

tm struct 
tm_sec dword	?
tm_min dword	?
tm_hour dword	?
tm_mday dword	?
tm_mon dword	?
tm_year dword	?
tm_wday dword	?
tm_yday dword	?
tm_isdst dword	?
tm ends

tmpTime DWORD ?
.code

; strcmp
; dest: eax
; src: ebx
myStrCmp proc
	pushfd
	mov edi, eax
	mov esi, ebx

	xor ecx, ecx

LOOP_BEGIN:
	mov eax, [edi + ecx]
	mov ebx, [esi + ecx]

	cmp eax, ebx
	jnz NOEQUES_LAB
	add ecx, 1

	test eax, eax
	jz EQUES_LAB
LOOP_END:
	jmp LOOP_BEGIN

EQUES_LAB:
	popfd
	mov eax, 1

	jmp END_LAB

NOEQUES_LAB:
	popfd
	xor eax,eax

END_LAB:

	ret
myStrCmp endp

; strcpy
; dest: eax
; src: ebx
myStrCpy proc
	pushfd
	mov edi,eax
	mov esi, ebx
	xor ecx,ecx
WHILE_BEGINE:
	mov ebx, [esi + ecx]
	mov [edi + ecx], ebx

	test ebx, ebx
	jz EXIT_LAB
	add ecx, 1
	jmp WHILE_BEGINE

EXIT_LAB:
	popfd
	ret

myStrCpy endp

; strlen
; src: eax
myStrLen proc
	mov edi,eax
	xor ecx,ecx
WHILE_BEGINE:
	mov ebx, [edi + ecx]
	test ebx, ebx
	jz EXIT_LAB
	add ecx, 1
	jmp WHILE_BEGINE

EXIT_LAB:
	ret
myStrLen endp

; 因系统库不起作用，造的轮子。。。
; 
myStrftime proc

	mov edi, esi
	mov edx, [esp + 4]
	mov ebx, [esp + 8]
	mov eax, [esp + 12]
	mov esi, [esp + 10H]


	pushfd



	mov ebx, [esi + 4 * 0]
	push ebx
	mov ebx, [esi + 4 * 1]
	push ebx
	mov ebx, [esi + 4 * 2]
	push ebx

	mov ebx, [esi + 4 * 3]
	push ebx
	mov ebx, [esi + 4 * 4]
	add ebx, 1
	push ebx
	mov ebx, [esi + 4 * 5]
	add ebx, 1900
	push ebx

	push eax
	push edx

	call crt_sprintf
	add esp, 32
	popfd

	mov esi,edi
	ret
myStrftime endp

; 格式化时间
; TimeStamp: DWORD* eax
; TimeStr: byte* esi
GetTimeStr proc
	push esi
	mov [tmpTime], eax
	lea eax, [tmpTime]
	push eax
	call crt_localtime
	add esp, 4

	pop esi
	
	; 时间结构体
	push eax
	; 格式化字符串
	push offset szTimeFormat
	; 大小
	push 100
	; 格式化字符串存放的位置
	mov ebx, [esi]
	push ebx
	call myStrftime
	add esp, 10H

	mov ebx, [esi]
	mov eax, ebx

	ret
GetTimeStr endp

; 打印时间
; 当前时间戳: eax
; 两种模式 时间戳为 0 ，时间戳为 指定
PrintTime proc
	push esi
	push eax
	call crt_time
	add esp, 4

	pop esi
	mov eax, eax
	call GetTimeStr

	push eax
	call crt_printf
	add esp, 4
	ret
	
PrintTime endp


; 初始化机器状态
InitMachine proc
	push ecx
	push edx
	push ebx
	push edi

	mov ecx, 0
	mov edx, 10000
	mov ebx, 0
	lea edi, [machineAry]

WHILE_BEGIN:
	cmp ecx, 16
	jz WHILE_END
	
	mov [edi], edx
	mov byte ptr[edi + 4], bl

	add edi, SIZEOF machineStatus
	add edx, 1
	add ecx, 1
	jmp WHILE_BEGIN

WHILE_END:

	pop edi
	pop ebx
	pop edx
	pop ecx
	ret


InitMachine endp


; 获取机器状态
; eax : 机器序号
; eax : 机器状态
GetMachineStatus proc
	push ecx
	push edx
	push ebx
	push edi

	; 越界判断
	cmp eax, 15
	JNC EXIT_LAB

	; 定位到机器位置
	lea edi, [machineAry]
	mov ecx, SIZEOF machineStatus
	imul eax, ecx
	add edi, eax

	xor eax, eax
	mov al, byte ptr[edi + 4]

EXIT_LAB:

	pop edi
	pop ebx
	pop edx
	pop ecx
	ret
GetMachineStatus endp

; 设置机器状态
; eax : 机器序号
; ebx : 机器状态
SetMachineStatus proc
	push ecx
	push edx
	push ebx
	push edi

	; 越界判断
	cmp eax, 15
	JNC EXIT_LAB

	; 定位到机器位置
	lea edi, [machineAry]
	mov ecx, SIZEOF machineStatus
	imul eax, ecx
	add edi, eax

	mov byte ptr[edi + 4], bl

EXIT_LAB:

	pop edi
	pop ebx
	pop edx
	pop ecx
	ret
SetMachineStatus endp

; 使用机器
; eax : 机器序号
UseMachine proc
	mov ebx, 1
	call SetMachineStatus
	ret
UseMachine endp	

; 取消使用机器
; eax : 机器序号
UnUseMachine proc
	mov ebx, 0
	call SetMachineStatus
	ret
UnUseMachine endp


; 初始化 信息
InitInfo proc
	call InitMachine

	; 卡信息链表初始化
	lea ebx, [cardInfoHeadLink]
	mov dword ptr ds:[ebx], 0
	add ebx, 4
	mov dword ptr ds:[ebx], 0
	add ebx, 4
	mov dword ptr ds:[ebx], 0
	add ebx, 4
	mov dword ptr ds:[ebx], 0



	ret
InitInfo endp

; 新增卡号
; 卡号: eax
; 密码: ebx
; 余额: ecx
AddCardInfo proc
	pushfd

	lea esi, [cardInfoHeadLink]

	; 就地添加
	mov edx, [edi]
	test edx, edx
	jnz ADD_NEW_LAB

	mov edx, [edi + 4]
	test edx, edx
	jnz ADD_NEW_LAB


ADD_ROOT_LAB:
	; 添加到头部

	mov dword ptr ds:[esi], 0
	mov dword ptr ds:[esi + 4], eax
	mov dword ptr ds:[esi + 8], ebx
	mov dword ptr ds:[esi + 12], ecx

	jmp END_LAB

ADD_NEW_LAB:
	; 添加到非头部
	mov ecx, SIZEOF cardInfoLinked
	push ecx
	call crt_malloc
	mov edi, eax

	mov dword ptr ds:[edi], 0
	mov dword ptr ds:[edi + 4], eax
	mov dword ptr ds:[edi + 8], ebx
	mov dword ptr ds:[edi + 12], ecx

	; 找到链表尾部
LOOP_BEGIN:
	mov eax, dword ptr ds:[esi]
	test eax, eax
	jz LOOP_END

	mov esi, dword ptr ds:[esi]
	jmp LOOP_BEGIN
LOOP_END:

	mov dword ptr ds:[esi], edi
	
	jmp END_LAB
END_LAB:

	popfd
	ret
AddCardInfo endp

; 查看历史记录
WatchHistory proc
	pushfd
	lea esi, [historyInfoHeadLinked]

	mov edi, esi
LOOP_BEGINE:
	test edi, edi
	jz LOOP_END

	mov edx, dword ptr ds:[edi + 4]
	push edx
	mov edx, dword ptr ds:[edi + 8]
	push edx
	mov edx, dword ptr ds:[edi + 12]
	push edx
	mov edx, dword ptr ds:[edi + 16]
	push edx
	push offset szHistoryFormat
	call crt_printf
	add esp, 20


	mov eax, [edi]
	mov edi, eax
	jmp LOOP_BEGINE
LOOP_END:
	

	popfd
	ret
WatchHistory endp

; 添加历史记录
; 机器号: eax
; 卡号: ebx
; 类型: ecx
; 时间(无需): edx
AddHistory proc
	pushfd
	lea esi, [historyInfoHeadLinked]

	; 如果下一个节点不为0 则添加一个新节点
	mov edx, [esi]
	test edx, edx
	jnz ADD_NEW_LAB

	mov edx, dword ptr ds:[esi + 4]
	test edx, edx
	jnz ADD_NEW_LAB

ADD_HEAD_LAB:
	mov dword ptr ds:[esi], 0
	mov dword ptr ds:[esi + 4], ecx
	mov dword ptr ds:[esi + 8], eax
	push 0
	call crt_time
	add esp, 4
	mov dword ptr ds:[esi + 12], eax
	mov dword ptr ds:[esi + 16], ebx
	jmp END_LAB
ADD_NEW_LAB:

LOOP_BEGIN:
	mov edi, esi
	mov eax, dword ptr ds:[edi]
	test eax, eax
	jnz LOOP_BEGIN

	mov edx, sizeof historyInfoLinked
	push eax
	push edx
	call crt_malloc
	add esp, 4
	mov esi, eax
	pop eax
	mov dword ptr ds:[edi], esi

	mov dword ptr ds:[esi], 0
	mov dword ptr ds:[esi + 4], ecx
	mov dword ptr ds:[esi + 8], eax
	push 0
	call crt_time
	add esp, 4
	mov dword ptr ds:[esi + 12], eax
	mov dword ptr ds:[esi + 16], ebx
	jmp END_LAB
END_LAB:

	popfd
	ret
AddHistory endp


; 上机
; 机器号: eax
; 卡号: ebx
; 密码: ecx
OnMachine proc
	push eax
	push ebx
	push ecx
	call UseMachine
	pop ecx
	pop ebx
	pop eax
	; 添加记录
	mov ecx, 1
	call AddHistory	

	ret

OnMachine endp

; 下机
; 机器号: ebx
DownMachine proc
	mov eax, ebx
	call UnUseMachine

	; 中间发生一个搜索历史记录，从历史记录中找到对应的卡号，找不到就不添加记录

	; 添加记录
	mov ecx, 2
	call AddHistory	

	ret
DownMachine endp


main PROC

	push ebp
	mov ebp,esp
	sub esp, 40H

	; flag 
	lea ebx, [ebp-4]

	; szCardId
	lea ebx, [ebp-8]
	push 100
	call crt_malloc
	add esp, 4
	mov [ebx], eax

	; szCardPass
	lea ebx, [ebp-12]
	push 100
	call crt_malloc
	add esp, 4
	mov [ebx], eax

	; szMachineId
	lea ebx, [ebp-10H]
	push 100
	call crt_malloc
	add esp, 4
	mov [ebx], eax

	; szCardPassOk
	lea ebx, [ebp-14H]
	push 100
	call crt_malloc
	add esp, 4
	mov [ebx], eax

	; szTimeStr
	lea ebx, [ebp-18H]
	push 100
	call crt_malloc
	add esp, 4
	mov [ebx], eax


BEGIN_LAB:
	
	lea ebx, dword ptr ds:[szCls]
	push ebx
	call crt_system
	add esp, 4

	lea ebx, dword ptr ds:[szMenu]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8
	; flag 
	lea ebx, [ebp-4]

	push ebx
	lea ebx, dword ptr ds:[FORMAT_D]
	push ebx
	call crt_scanf
	add esp, 8

	mov ebx, [ebp - 4]

	cmp ebx, 1
	jz ONMACHINE_LAB

	cmp ebx, 2
	jz DOWNMACHINE_LAB

	cmp ebx, 3
	jz REGISTER_LAB

	cmp ebx, 4
	jz PRINTHIST_LAB

	cmp ebx, 5
	jz EXIT_LAB

	jmp END_LAB



ONMACHINE_LAB:
	; 输入机器号码
	lea ebx, dword ptr ds:[szMachineId]
	push ebx
	call crt_printf

	add esp, 4

	lea ebx, dword ptr ds:[ebp-10H]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 8

	; 输入卡号
	lea ebx, dword ptr ds:[szCardId]
	push ebx
	call crt_printf
	add esp, 4
	lea ebx, dword ptr ds:[ebp-8]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 8

	; 输入卡密码
	lea ebx, dword ptr ds:[szCardPass]
	push ebx
	call crt_printf
	add esp, 4
	lea ebx, dword ptr ds:[ebp-12]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 8

	; 打印开始时间
	lea ebx, dword ptr ds:[szStartTime]
	push ebx
	call crt_printf
	add esp, 4
	lea esi, dword ptr ds:[ebp-18H]
	xor eax,eax
	call PrintTime

	; 是否确认操作
	lea ebx, dword ptr ds:[szOK]
	push ebx
	call crt_printf
	add esp, 4

	lea ebx, [ebp-14H]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 4
	test eax, eax
	; zf == 1 时跳转成立
	jz ONMACHINE_ERROR_LAB
	
	lea ebx, [ebp-14H]
	xor eax,eax
	mov dl, byte ptr ds:[ebx]
	cmp dl, 89
	jnz ONMACHINE_ERROR_LAB
	add ebx, 1
	mov dl, byte ptr ds:[ebx]
	cmp dl, 0
	jnz ONMACHINE_ERROR_LAB

	lea eax, dword ptr ds:[ebp - 10H]
	lea ebx, dword ptr ds:[ebp - 8]
	lea ecx, dword ptr ds:[ebp - 12]
	lea edx, dword ptr ds:[ebp - 12H]

	call OnMachine

	push offset szOnMachineSucessHint
	push offset FORMAT_S
	call crt_printf
	add esp, 8


	jmp END_LAB


ONMACHINE_ERROR_LAB:
	lea ebx, [szOperatorChanelHint]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8



	jmp END_LAB

DOWNMACHINE_LAB:
	
	lea ebx, dword ptr ds:[szMachineId]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8

	lea ebx, dword ptr ds:[ebp-10H]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 8
	test eax,eax
	jz DOWNMACHINE_ERROR_LAB

	lea ebx, dword ptr ds:[szEndTime]
	push ebx
	lea ebx, dword ptr ds:[FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8

	lea esi, dword ptr ds:[ebp-18H]
	xor eax,eax
	call PrintTime

	; 是否确认操作
	lea ebx, dword ptr ds:[szOK]
	push ebx
	call crt_printf
	add esp, 4

	lea ebx, [ebp-14H]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 4
	test eax, eax
	; zf == 1 时跳转成立
	jz DOWNMACHINE_ERROR_LAB
	
	lea ebx, [ebp-14H]
	xor eax,eax
	mov dl, byte ptr ds:[ebx]
	cmp dl, 89
	jnz DOWNMACHINE_ERROR_LAB
	add ebx, 1
	mov dl, byte ptr ds:[ebx]
	cmp dl, 0
	jnz DOWNMACHINE_ERROR_LAB

	call DownMachine


	jmp END_LAB
DOWNMACHINE_ERROR_LAB:
	lea ebx, [szOperatorChanelHint]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8

	jmp END_LAB

REGISTER_LAB:
	
	push offset szCardId
	call crt_printf
	add esp, 4

	lea ebx, [ebp - 8]
	push ebx
	push offset FORMAT_S
	call crt_scanf
	add esp, 8

	push offset szCardPass
	call crt_printf
	add esp, 4
	lea ebx, [ebp-12]
	push ebx
	push offset FORMAT_S
	call crt_scanf
	add esp, 8
	

	push offset szCardPassOk
	call crt_printf
	add esp, 4
	lea ebx, [ebp-14H]
	push ebx
	push offset FORMAT_S
	call crt_scanf
	add esp, 8

	; 比较密码
	lea eax, [ebp-14H]
	lea ebx, [ebp-12]
	call myStrCmp

	test eax, eax
	jz REGISTER_ERROR_LAB

	; 是否确认操作
	lea ebx, dword ptr ds:[szOK]
	push ebx
	call crt_printf
	add esp, 4

	lea ebx, [ebp-14H]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_scanf
	add esp, 4
	test eax, eax
	; zf == 1 时跳转成立
	jz REGISTER_ERROR_LAB
	
	lea ebx, [ebp-14H]
	xor eax,eax
	mov dl, byte ptr ds:[ebx]
	cmp dl, 89
	jnz REGISTER_ERROR_LAB
	add ebx, 1
	mov dl, byte ptr ds:[ebx]
	cmp dl, 0
	jnz REGISTER_ERROR_LAB

	call AddCardInfo
	jmp END_LAB

REGISTER_ERROR_LAB:
	lea ebx, [szOperatorChanelHint]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8

	jmp END_LAB
PRINTHIST_LAB:
	call WatchHistory
	
	jmp END_LAB

PRINTHIST_ERROR_LAB:
	lea ebx, [szOperatorChanelHint]
	push ebx
	lea ebx, [FORMAT_S]
	push ebx
	call crt_printf
	add esp, 8

	jmp END_LAB

END_LAB:
	lea ebx, dword ptr ds:[szPause]
	push ebx
	call crt_system
	add esp, 4
	
	jmp BEGIN_LAB

EXIT_LAB:

	mov esp, ebp
	pop ebp
	ret 

main ENDP

END  main


