#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.4
 Author:         myName

 Script Function:
	Template AutoIt script.

	TODO
	- GUI (Ip + SNMP Pulic + SNMP Version) DONE
	- Ping test before SNMP
	- timeout....   <----------
	- Print Result
	- validate cenas (resultados......
	- save last used value

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

#include <File.au3>
#include <Array.au3>
#include <MsgBoxConstants.au3>
#Include <String.au3>
#Include 'snmp_UDF-v1.7.4.au3'
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GUIButton.au3>

Global $interDesc [0]
Global $interStatus [0]
Global $interLastCh [0]

Global $deviceUptime = 0

Global $wmiLocator
Global $wmiService

;$strTargetSnmpDevice = "192.168.249.253" ; Device IP Address

Global $dest_IP = "172.21.1.110" 			; Destination Address (change it)
Global $Port = 161 							; UDP 161  = SNMP port
Global $SNMP_Version = 2					; SNMP v2c (1 for SNMP v1)
Global $SNMP_Community = "Public"			; SNMPString(Community) (change it)
Global $SNMP_ReqID = 1
Global $SNMP_Command
Global $Start = 1
Global $result
Global $Socket

Global $idMyedit
Global $debug

GUIInterface()


Func GUIInterface()

	#Region ### START Koda GUI section ### Form=
	$Form1 = GUICreate("Switch Last Port Change", 436, 492, 192, 124)
	$Label1 = GUICtrlCreateLabel("IP: ", 88, 56, 20, 17)
	$Label2 = GUICtrlCreateLabel("SNMP Version:", 32, 88, 76, 17)
	$Label3 = GUICtrlCreateLabel("SNMP Community: ", 16, 112, 95, 17)
	$Input1 = GUICtrlCreateInput("172.21.1.112", 120, 56, 121, 21)
	GUICtrlSetLimit(-1, 13)
	;$Combo1 = GUICtrlCreateCombo(" SNMP v1| SNMP v2c", 120, 88, 121, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))

	$ComboBox = GUICtrlCreateCombo('SNMP v2c', 120, 88, 121, 25)
	GUICtrlSetData($ComboBox, "SNMP v1")
;	_GUICtrlComboBox_SelectString($ComboBox, "SNMP v2c")

	$Input2 = GUICtrlCreateInput("Public", 120, 112, 121, 21)
	$Button1 = GUICtrlCreateButton("GO", 264, 160, 145, 41)
	$ButtonPing = GUICtrlCreateButton("Ping", 264, 56, 145, 21)
	$Checkbox1 = GUICtrlCreateCheckbox("Debug", 16, 192, 89, 17)

	$idMyedit = GUICtrlCreateEdit("", 10, 220, 401, 238, BitOR($WS_VSCROLL, $GUI_SS_DEFAULT_EDIT, $ES_READONLY))
	GUICtrlSetFont(-1, 8, 400, 0, "Courier New")
	GUICtrlSetColor(-1, 0xFFFFFF)
	GUICtrlSetBkColor(-1, 0x000000)
	GUICtrlSetLimit(-1, 50000)

	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $Button1
				Local $input_IP = GUICtrlRead($Input1)

				if (_IsIP4($input_IP)) Then
					$dest_IP = $input_IP
				else
					MsgBox(0, 1, "IP address not valid")
					ContinueCase
				EndIf
				if ($debug) Then
						_writeLog(GUICtrlRead($ComboBox))
				EndIf

				; SNMP v2c (1 for SNMP v1)
				If (GUICtrlRead($ComboBox) = "SNMP v2c") Then
					$SNMP_Version = "2"
				else
					$SNMP_Version = "1"
				endif
				if ($debug) Then
					_writeLog($input_IP)
					_writeLog(_IsIP4($input_IP))
					_writeLog($SNMP_Version)
				EndIf

				$SNMP_Community = GUICtrlRead($Input2)			; SNMPString(Community) (change it)
				If (StringLen($SNMP_Community) = 0) Then
					MsgBox(0, 1, "SNMP Community can't be empty")
					ContinueCase
				EndIf

				$iPing = PingTest($input_IP)
				If $iPing Then
					DoIt()
				Else
					MsgBox(0, 1, "can't reach device")
					ContinueCase
				EndIf
			Case $ButtonPing
				Local $input_IP = GUICtrlRead($Input1)
				_writeLog($input_IP)
				_writeLog(_IsIP4($input_IP))
				if (_IsIP4($input_IP)) Then
					$iPing = PingTest($input_IP)
					If $iPing Then ; If a value greater than 0 was returned then display the following message.
						_writeLog("The roundtrip-time took: " & $iPing & "ms.")
					Else
						_writeLog("An error occurred with @error value of: " & @error)
					EndIf
				EndIf
			 Case $Checkbox1
                If BitAND(GUICtrlRead($Checkbox1), $BN_CLICKED) = $BN_CLICKED Then
                    If _GUICtrlButton_GetCheck($Checkbox1) Then
                        $debug = True ; Checkbox checked...
                    Else
                        $debug = False ; Checkbox unchecked...
                    EndIf
                EndIf
			Case $GUI_EVENT_CLOSE
				Exit

		EndSwitch
	WEnd


EndFunc   ;==>GUIInterface


Func DoIt()
	UDPStartUp()
	$Socket = UDPopen($dest_IP, $Port)

	Global $SNMP_OID = "1.3.6.1.2.1.1.3.0"     ;  Equipment UPTIME
	;$SNMP_Command = _SNMPBuildPacket($SNMP_OID, $SNMP_Community,$SNMP_Version, $SNMP_ReqID, "A0")
	$SNMP_Command = _SNMPBuildPacket($SNMP_OID, $SNMP_Community,$SNMP_Version, $SNMP_ReqID, "A0")
	UDPSend($Socket, $SNMP_Command)
	_StartListener()
	sleep (200)

	;_ArrayDisplay($SNMP_Util, "GetRequest 1x OID")
	;_ArrayDisplay($SNMP_Received, "$SNMP_Received - EXAMPLE")
	$deviceUptime = $SNMP_Util[1][1]*100

	$snmpR = SNMPReq("1.3.6.1.2.1.2.2.1.2")   ;  Interfaces DESC
	;msgbox(0,'', UBound($snmpR))
	For $i = 0 to UBound($snmpR, 1) - 1
	   if (StringInStr($snmpR[$i][0], "1.3.6.1.2.1.2.2.1.2") >= 1) Then
		  _ArrayAdd($interDesc, $snmpR[$i][1])
	   EndIf
	Next

	;_ArrayDisplay($interDesc, "$interDesc")

	$snmpR = SNMPReq("1.3.6.1.2.1.2.2.1.8")   ;  Interfaces STATUS    1-up, 2-down, 3-testing
	For $i = 0 to UBound($snmpR, 1) - 1
	   if (StringInStr($snmpR[$i][0], "1.3.6.1.2.1.2.2.1.8") >= 1) Then
		   Switch ($snmpR[$i][1])
			   Case "1"
				   $status = "Up"
			   Case "2"
				   $status = "Down"
			   Case "3"
				   $status = "Testing"
			   Case Else
				   $status = "N/D"
			EndSwitch

;if (($snmpR[$i][1]) == "1") Then
;			$status = "Up"
;		 Else
;			$status = "Down"
;		  EndIf
		  _ArrayAdd($interStatus, $status)
	   EndIf
	Next

	$snmpR = SNMPReq("1.3.6.1.2.1.2.2.1.9")   ;  Interfaces LAST CHANGE
	;_ArrayDisplay($snmpR, "last change")
	For $i = 0 to UBound($snmpR, 1) - 1
	   if (StringInStr($snmpR[$i][0], "1.3.6.1.2.1.2.2.1.9") >= 1) Then
		  $values = StringSplit($snmpR[$i][1], " ")
		  $diff = timeticks2Days($deviceUptime - ($values[1]*100))
		  _ArrayAdd($interLastCh, $diff & "d")
	   EndIf
	Next

	$ports = UBound($snmpR)-1

	Global $interfaces[$ports][3]

	For $i = 0 to $ports-1
		$interfaces[$i][0] = $interDesc[$i]
		$interfaces[$i][1] = $interStatus[$i]
		$interfaces[$i][2] = $interLastCh[$i]
	Next

	_ArrayDisplay($interfaces, "Device uptime: " & timeticks2Days($deviceUptime) & "d","",64,Default, "Interface|Status|Last Change")
EndFunc

Func timeticks2Days($tticks)
    Return (floor($tticks/8640000))
EndFunc


Func getText($text)
	$ini = StringInStr($text, chr(34))
	$text = StringMid($text, $ini+1)
	$ini = StringInStr($text, chr(34))
	$text = StringLeft($text, $ini-1)
	Return $text
EndFunc


Func SNMPReq ($OID)
	  ;GetBulk (ifTable - ifDescr) 32 values returned
   Global $SNMP_OID = $OID
   $SNMP_Command = _SNMPBuildPacket($SNMP_OID, $SNMP_Community,$SNMP_Version, $SNMP_ReqID, "A5", "20")
   UDPSend($Socket, $SNMP_Command)
   _StartListener()
   sleep (200)
   ;_ArrayDisplay($SNMP_Util, "GetBulk")
   Return $SNMP_Util
EndFunc

Func parseSNMPResp($array)
   Local $arrayRes[0]
   For $i = 0 to UBound($array, 1) - 1
	  if (StringInStr($array[$i][0], "1.3.6.1.2.1.2.2.1.2.101") >= 1) Then
		 _ArrayAdd($arrayRes, $array[$i][1])
		 ;msgbox(0,'', $array[$i][0] & "  " & $array[$i][1] )
	  EndIf
   Next
   return $array
EndFunc


Func PingTest($host)
    ; Ping the AutoIt website with a timeout of 250ms.
    Local $iPing = Ping($host, 750)

;If $iPing Then ; If a value greater than 0 was returned then display the following message.
;        MsgBox($MB_SYSTEMMODAL, "", "The roundtrip-time took: " & $iPing & "ms.")
;    Else
;        MsgBox($MB_SYSTEMMODAL, "", "An error occurred with @error value of: " & @error)
;	 EndIf
	 Return $iPing
EndFunc


Func _StartListener()
	If $Start = 1 Then
		While (1)
			$srcv = UDPRecv($Socket, 4096)
			If ($srcv <> "") Then
				$result = _ShowSNMPReceived ($srcv)
				ConsoleWrite($srcv &@CRLF)
				ExitLoop
			EndIf
		 sleep(100)
		 WEnd
		 ;_ArrayDisplay($result)
	EndIf
EndFunc

Func OnAutoItExit()
    UDPCloseSocket($Socket)
    UDPShutdown()
EndFunc

Func _IsIP4($sIP4)
    Return StringRegExp($sIP4, '^(?:(?:2(?:[0-4]\d|5[0-5])|1?\d{1,2})\.){3}(?:(?:2(?:[0-4]\d|5[0-5])|1?\d{1,2}))$')
    ; Return StringRegExp($sIP4, '^(?:(?:2(?:[0-4][\d|5[0-5])|[0-1]?\d{1,2})\.){3}(?:(?:2(?:[0-4]\d|5[0-5])|[0-1]?\d{1,2}))$')
EndFunc


Func _writeLog($text)
	GUICtrlSetData($idMyedit, $text & @CRLF, 1)
EndFunc   ;==>_writeLog


;~ /*
;~    14/03/2018 17:25:42 (177 ms) : 1.3.6.1.2.1.2.2.1.2.10101 = "GigabitEthernet0/1" [ASN_OCTET_STR]
;~    14/03/2018 17:25:43 (1946 ms) : 1.3.6.1.2.1.2.2.1.8.10126 = "2" [ASN_INTEGER]
;~    14/03/2018 17:25:44 (2116 ms) : 1.3.6.1.2.1.2.2.1.9.10113 = "850452656" [ASN_TIMETICKS]


;~ 1.3.6.1.2.1.2.2.1.1 - ifIndex
;~ 1.3.6.1.2.1.2.2.1.2 - ifDescr
;~ 1.3.6.1.2.1.2.2.1.3 - ifType
;~ 1.3.6.1.2.1.2.2.1.4 - ifMtu
;~ 1.3.6.1.2.1.2.2.1.5 - ifSpeed
;~ 1.3.6.1.2.1.2.2.1.6 - ifPhysAddress
;~ 1.3.6.1.2.1.2.2.1.7 - ifAdminStatus
;~ 1.3.6.1.2.1.2.2.1.8 - ifOperStatus
;~ 1.3.6.1.2.1.2.2.1.9 - ifLastChange
;~ 1.3.6.1.2.1.2.2.1.10 - ifInOctets
;~ 1.3.6.1.2.1.2.2.1.11 - ifInUcastPkts
;~ 1.3.6.1.2.1.2.2.1.12 - ifInNUcastPkts
;~ 1.3.6.1.2.1.2.2.1.13 - ifInDiscards
;~ 1.3.6.1.2.1.2.2.1.14 - ifInErrors
;~ 1.3.6.1.2.1.2.2.1.15 - ifInUnknownProtos
;~ 1.3.6.1.2.1.2.2.1.16 - ifOutOctets
;~ 1.3.6.1.2.1.2.2.1.17 - ifOutUcastPkts
;~ 1.3.6.1.2.1.2.2.1.18 - ifOutNUcastPkts
;~ 1.3.6.1.2.1.2.2.1.19 - ifOutDiscards
;~ 1.3.6.1.2.1.2.2.1.20 - ifOutErrors
;~ 1.3.6.1.2.1.2.2.1.21 - ifOutQLen
;~ 1.3.6.1.2.1.2.2.1.22 - ifSpecific

;~ */