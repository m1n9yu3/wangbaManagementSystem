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


; ����нṹ������
machineStatus struct
machineId dword	?
machineOn db ?
; ����
cardOrder DWORD ?
machineStatus ends

; ����Ϣ����
cardInfoLinked struct
; ��һ������
NextLink DWORD ?
; ����
cardOrder DWORD ?
; ������
cardPass DWORD ?
; �����
cardBalance DWORD ?

cardInfoLinked ends

; ������: eax
; ����: ebx
; ����: ecx
; ���: edx

; ��ʷ��¼����
historyInfoLinked struct
; ��һ������
NextLink DWORD ?
; ״̬
machineOn DWORD ?
; ������
machineId dword	?
; ʱ���
time DWORD ?
; ����
cardOrder DWORD ?
historyInfoLinked ends

; �������� ����״̬ 0, 1
machineAry machineStatus 16 dup(<>)
; ������
cardInfoHeadLink cardInfoLinked <>
; ��ʷ��¼���� 
historyInfoHeadLinked historyInfoLinked <>

FORMAT_S db '%s',0,0
FORMAT_D db '%d',0,0


szCls db 'cls',0,0
szPause db 'pause',0,0
szMenu db '���ɼƷѹ���ϵͳ',12,'1.�ϻ�����',12,'2.�»�����',12,'3.ע���»�Ա',12,'4.�鿴��ʷ��¼',12,'5.�˳�',12,'���������ѡ��',0,0

szMachineId db '��������:', 0,0
szFinalTime db '����ʱ��:',0,0
szOK db 10,12,'ȷ�ϣ�Y/N',0,0
szCardId db '����:',0,0
szCardPass db '����:',0,0
szStartTime db '��ʼʱ��:',0,0
szEndTime db '����ʱ��:',0,0

szCardPassOk db 'ȷ������:',0,0

szOnMachineSucessHint db '�����ɹ�����ʼ��ʱ...',12,0,0
szOperatorChanelHint db '����ȡ��',12,0,0

szDownMachineSucessHint db '�ܹ�ʱ��%d����, ����%d Ԫ',12,0,0
szRegisterMemberHint db '��ϲ�㣬ע��ɹ������Ŀ�����%s',12, 0,0
szTimeFormat db '%d-%d-%d %d:%d:%d',0,0

szHistoryFormat db '������: %s - ʱ���: %d- ����: %s-��������: %d',12,0,0

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

; ��ϵͳ�ⲻ�����ã�������ӡ�����
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

; ��ʽ��ʱ��
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
	
	; ʱ��ṹ��
	push eax
	; ��ʽ���ַ���
	push offset szTimeFormat
	; ��С
	push 100
	; ��ʽ���ַ�����ŵ�λ��
	mov ebx, [esi]
	push ebx
	call myStrftime
	add esp, 10H

	mov ebx, [esi]
	mov eax, ebx

	ret
GetTimeStr endp

; ��ӡʱ��
; ��ǰʱ���: eax
; ����ģʽ ʱ���Ϊ 0 ��ʱ���Ϊ ָ��
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


; ��ʼ������״̬
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


; ��ȡ����״̬
; eax : �������
; eax : ����״̬
GetMachineStatus proc
	push ecx
	push edx
	push ebx
	push edi

	; Խ���ж�
	cmp eax, 15
	JNC EXIT_LAB

	; ��λ������λ��
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

; ���û���״̬
; eax : �������
; ebx : ����״̬
SetMachineStatus proc
	push ecx
	push edx
	push ebx
	push edi

	; Խ���ж�
	cmp eax, 15
	JNC EXIT_LAB

	; ��λ������λ��
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

; ʹ�û���
; eax : �������
UseMachine proc
	mov ebx, 1
	call SetMachineStatus
	ret
UseMachine endp	

; ȡ��ʹ�û���
; eax : �������
UnUseMachine proc
	mov ebx, 0
	call SetMachineStatus
	ret
UnUseMachine endp


; ��ʼ�� ��Ϣ
InitInfo proc
	call InitMachine

	; ����Ϣ�����ʼ��
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

; ��������
; ����: eax
; ����: ebx
; ���: ecx
AddCardInfo proc
	pushfd

	lea esi, [cardInfoHeadLink]

	; �͵����
	mov edx, [edi]
	test edx, edx
	jnz ADD_NEW_LAB

	mov edx, [edi + 4]
	test edx, edx
	jnz ADD_NEW_LAB


ADD_ROOT_LAB:
	; ��ӵ�ͷ��

	mov dword ptr ds:[esi], 0
	mov dword ptr ds:[esi + 4], eax
	mov dword ptr ds:[esi + 8], ebx
	mov dword ptr ds:[esi + 12], ecx

	jmp END_LAB

ADD_NEW_LAB:
	; ��ӵ���ͷ��
	mov ecx, SIZEOF cardInfoLinked
	push ecx
	call crt_malloc
	mov edi, eax

	mov dword ptr ds:[edi], 0
	mov dword ptr ds:[edi + 4], eax
	mov dword ptr ds:[edi + 8], ebx
	mov dword ptr ds:[edi + 12], ecx

	; �ҵ�����β��
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

; �鿴��ʷ��¼
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

; �����ʷ��¼
; ������: eax
; ����: ebx
; ����: ecx
; ʱ��(����): edx
AddHistory proc
	pushfd
	lea esi, [historyInfoHeadLinked]

	; �����һ���ڵ㲻Ϊ0 �����һ���½ڵ�
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


; �ϻ�
; ������: eax
; ����: ebx
; ����: ecx
OnMachine proc
	push eax
	push ebx
	push ecx
	call UseMachine
	pop ecx
	pop ebx
	pop eax
	; ��Ӽ�¼
	mov ecx, 1
	call AddHistory	

	ret

OnMachine endp

; �»�
; ������: ebx
DownMachine proc
	mov eax, ebx
	call UnUseMachine

	; �м䷢��һ��������ʷ��¼������ʷ��¼���ҵ���Ӧ�Ŀ��ţ��Ҳ����Ͳ���Ӽ�¼

	; ��Ӽ�¼
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
	; �����������
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

	; ���뿨��
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

	; ���뿨����
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

	; ��ӡ��ʼʱ��
	lea ebx, dword ptr ds:[szStartTime]
	push ebx
	call crt_printf
	add esp, 4
	lea esi, dword ptr ds:[ebp-18H]
	xor eax,eax
	call PrintTime

	; �Ƿ�ȷ�ϲ���
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
	; zf == 1 ʱ��ת����
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

	; �Ƿ�ȷ�ϲ���
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
	; zf == 1 ʱ��ת����
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

	; �Ƚ�����
	lea eax, [ebp-14H]
	lea ebx, [ebp-12]
	call myStrCmp

	test eax, eax
	jz REGISTER_ERROR_LAB

	; �Ƿ�ȷ�ϲ���
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
	; zf == 1 ʱ��ת����
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


