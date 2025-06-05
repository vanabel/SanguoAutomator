#Requires AutoHotkey v2.0

; ========== GDI+ Functions ==========
Gdip_Startup() {
    static pToken := 0
    
    ; 如果已经初始化，直接返回token
    if pToken
        return pToken
    
    ; 加载GDI+库
    if !DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
        DllCall("LoadLibrary", "str", "gdiplus")
    
    ; 创建GDI+启动输入结构
    si := Buffer(24, 0)                ; sizeof(GdiplusStartupInput) = 24
    NumPut("uint", 1, si, 0)           ; GdiplusVersion = 1
    NumPut("ptr", 0, si, 8)            ; DebugEventCallback = 0
    NumPut("int", 0, si, 16)           ; SuppressBackgroundThread = 0
    NumPut("int", 0, si, 20)           ; SuppressExternalCodecs = 0
    
    ; 启动GDI+
    if !DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken, "ptr", si, "ptr", 0) {
        if (A_LastError = 183) {  ; ERROR_ALREADY_EXISTS
            ; 尝试获取已存在的token
            if DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken, "ptr", si, "ptr", 0)
                return pToken
        }
        throw Error("GDI+初始化失败: " A_LastError)
    }
    
    return pToken
}

Gdip_Shutdown(pToken) {
    static shutdownCount := 0
    
    if pToken {
        shutdownCount++
        ; 只在最后一次调用时真正关闭GDI+
        if (shutdownCount >= 1) {
            DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
            if hModule := DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
                DllCall("FreeLibrary", "ptr", hModule)
            shutdownCount := 0
        }
    }
}

Gdip_GetEncoderClsid(format) {
    ; 获取编码器CLSID
    if !DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &numEncoders:=0, "uint*", &size:=0)
        throw Error("获取编码器大小失败: " A_LastError)
    
    encoders := Buffer(size)
    if !DllCall("gdiplus\GdipGetImageEncoders", "uint", numEncoders, "uint", size, "ptr", encoders)
        throw Error("获取编码器失败: " A_LastError)
    
    ; 查找指定格式的编码器
    loop numEncoders {
        encoder := encoders + (A_Index - 1) * 76  ; sizeof(ImageCodecInfo) = 76
        if (StrGet(NumGet(encoder + 32, "ptr"), "UTF-16") = format) {
            clsid := Buffer(16, 0)
            DllCall("RtlMoveMemory", "ptr", clsid, "ptr", encoder, "ptr", 16)
            return clsid
        }
    }
    throw Error("未找到指定格式的编码器: " format)
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, clsid, quality:=75) {
    ; 创建编码器参数
    ep := Buffer(24 + A_PtrSize, 0)     ; sizeof(EncoderParameters) = 24 + A_PtrSize
    NumPut("uint", 1, ep, 0)            ; Count
    NumPut("uint", 1, ep, 16)           ; Type
    NumPut("uint", quality, ep, 20)     ; Value
    
    ; 保存图片
    if !DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "str", sOutput, "ptr", clsid, "ptr", ep)
        throw Error("保存图片失败: " A_LastError)
    
    return true
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, hPalette:=0) {
    ; 获取位图信息
    bm := Buffer(24, 0)  ; sizeof(BITMAP) = 24
    if !DllCall("GetObject", "ptr", hBitmap, "int", 24, "ptr", bm)
        throw Error("获取位图对象失败: " A_LastError)
    
    width := NumGet(bm, 4, "int")
    height := NumGet(bm, 8, "int")
    
    ; 创建位图信息结构
    bi := Buffer(40, 0)  ; sizeof(BITMAPINFOHEADER) = 40
    NumPut("uint", 40, bi, 0)           ; biSize
    NumPut("uint", width, bi, 4)        ; biWidth
    NumPut("uint", height, bi, 8)       ; biHeight
    NumPut("ushort", 1, bi, 12)         ; biPlanes
    NumPut("ushort", 32, bi, 14)        ; biBitCount
    NumPut("uint", 0, bi, 16)           ; biCompression
    
    ; 创建DC和选择位图
    hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    if !hdc
        throw Error("创建DC失败: " A_LastError)
    
    DllCall("SelectObject", "ptr", hdc, "ptr", hBitmap)
    
    ; 创建位图数据缓冲区
    size := width * height * 4
    pBits := Buffer(size, 0)
    
    ; 获取位图数据
    if !DllCall("GetDIBits", "ptr", hdc, "ptr", hBitmap, "uint", 0, "uint", height, "ptr", pBits, "ptr", bi, "uint", 0)
        throw Error("获取位图数据失败: " A_LastError)
    
    ; 创建GDI+位图
    if !DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", width, "int", height, "int", width * 4, "int", 0x26200A, "ptr", pBits, "ptr*", &pBitmap:=0) {
        ; 如果失败，尝试使用GdipCreateBitmapFromHBITMAP
        if !DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBitmap, "ptr", hPalette, "ptr*", &pBitmap:=0)
            throw Error("创建GDI+位图失败: " A_LastError)
    }
    
    ; 清理资源
    DllCall("DeleteDC", "ptr", hdc)
    
    return pBitmap
}

Gdip_DisposeImage(pBitmap) {
    if pBitmap
        return DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    return 0
} 