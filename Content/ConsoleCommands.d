/***********************************\
            CONSOLECOMMANDS
\***********************************/

const int zCConsole__Register           = 7875296; //0x782AE0
const int zCConsoleOutputOverwriteAddr  = 7142904; //0x6CFDF8 // Hook length 9

const int CC_Enable = 1; // Set to zero to disable all console commands (e.g. for a final mod build)

//========================================
// [internal] Class
//========================================
class CCItem {
    var int fncID;
    var string cmd;
};
instance CCItem@(CCItem);

var int _CC_Symbol;
var string _CC_command;

//========================================
// Check if command is registered
//========================================
func int CC_Active(var func function) {
    _CC_Symbol = MEM_GetFuncPtr(function);
    foreachHndl(CCItem@, _CC_Active);
    return !_CC_Symbol;
};

func int _CC_Active(var int hndl) {
    if(MEM_ReadInt(getPtr(hndl)) != _CC_Symbol) {
        return continue;
    };
    _CC_Symbol = 0;
    return break;
};

//========================================
// Register a new command for the console
//========================================
func void CC_Register(var func function, var string commandPrefix, var string description) {
    const int hook = 0;
    if (!hook) {
        HookEngineF(zCConsoleOutputOverwriteAddr, 9, _CC_Hook);
        hook = 1;
    };
    // Only add if not already present
    if(CC_Active(function)) {
        return;
    };
    commandPrefix = STR_Upper(commandPrefix);
    // Register auto-completion
    var int descPtr; descPtr = _@s(description);
    var int comPtr; comPtr = _@s(commandPrefix);
    const int call = 0;
    if (CALL_Begin(call)) {
        CALL_PtrParam(_@(descPtr));
        CALL_PtrParam(_@(comPtr));
        CALL__thiscall(_@(zcon_address), zCConsole__Register);
        call = CALL_End();
    };
    // Add function
    var int hndl; hndl = new(CCItem@);
    var CCItem itm; itm = get(hndl);
    itm.fncID = MEM_GetFuncPtr(function);
    itm.cmd = commandPrefix;
};

//========================================
// Remove command
//========================================
func void CC_Remove(var func function) {
    _CC_Symbol = MEM_GetFuncPtr(function);
    foreachHndl(FFItem@, _CC_RemoveL);
};

func int _CC_RemoveL(var int hndl) {
    if(MEM_ReadInt(getPtr(hndl)) != _CC_Symbol) {
        return continue;
    };
    delete(hndl);
    return break;
};

//========================================
// [internal] Engine hook
//========================================
func void _CC_Hook() {
    _CC_command = MEM_ReadString(MEM_ReadInt(ESP+1064)); // esp+424h+4h

    if (!CC_Enable) {
        return;
    };

    MEM_PushIntParam(CCItem@);
    MEM_GetFuncID(ConsoleCommand);
    MEM_StackPos.position = foreachHndl_ptr;
};
func int ConsoleCommand(var int hndl) {
    var CCItem itm; itm = get(hndl);
    var int cmdLen; cmdLen = STR_Len(itm.cmd);

    if (STR_Len(_CC_command) >= cmdLen) {
        if (Hlp_StrCmp(STR_Prefix(_CC_command, cmdLen), itm.cmd)) {
            MEM_PushStringParam(STR_SubStr(_CC_command, cmdLen, STR_Len(_CC_command)-cmdLen));
            MEM_CallByPtr(itm.fncID);
            var string ret; ret = MEM_PopStringResult();
            if (!Hlp_StrCmp(ret, "")) {
                MEM_WriteString(EAX, ret);
                return rBreak;
            };
        };
    };
    return rContinue;
};
