#Requires AutoHotkey v2.0

; ========== GDI+ 函数库 ==========
; 作者: mmikeww
; 版本: 1.0.0
; 描述: GDI+ 函数库，用于截图和图像处理

; ========== GDI+ 初始化 ==========
Gdip_Startup() {
    if !DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
        DllCall("LoadLibrary", "str", "gdiplus")
    
    si := Buffer(24, 0)                ; sizeof(GdiplusStartupInput) = 24
    NumPut("uint", 1, si)              ; GdiplusVersion = 1
    if DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken:=0, "ptr", si, "ptr", 0)
        return 0
    return pToken
}

; ========== GDI+ 关闭 ==========
Gdip_Shutdown(pToken) {
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
    if hModule := DllCall("GetModuleHandle", "str", "gdiplus", "ptr")
        DllCall("FreeLibrary", "ptr", hModule)
    return 0
}

; ========== 从屏幕创建位图 ==========
Gdip_BitmapFromScreen(Area) {
    if !Area
        Area := "0|0|" A_ScreenWidth "|" A_ScreenHeight
    
    Area := StrSplit(Area, "|")
    x := Area[1], y := Area[2], w := Area[3], h := Area[4]
    
    ; 创建屏幕DC
    hdc := DllCall("GetDC", "ptr", 0, "ptr")
    ; 创建兼容DC
    hdc2 := DllCall("CreateCompatibleDC", "ptr", hdc, "ptr")
    ; 创建位图
    hbm := DllCall("CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
    ; 选择位图到DC
    DllCall("SelectObject", "ptr", hdc2, "ptr", hbm)
    ; 复制屏幕内容到位图
    DllCall("BitBlt", "ptr", hdc2, "int", 0, "int", 0, "int", w, "int", h, "ptr", hdc, "int", x, "int", y, "uint", 0x00CC0020)
    
    ; 创建GDI+位图
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &pBitmap)
    
    ; 清理
    DllCall("DeleteObject", "ptr", hbm)
    DllCall("DeleteDC", "ptr", hdc2)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)
    
    return pBitmap
}

; ========== 保存位图到文件 ==========
Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality:=75) {
    ; 获取编码器CLSID
    if !CLSID := Gdip_GetEncoderClsid("image/png")
        return -1
    
    ; 创建编码器参数
    ep := Buffer(24+2*A_PtrSize, 0)
    NumPut("uint", 1, ep, 0)           ; 参数数量
    NumPut("uint", 1, ep, 16)          ; 参数类型 (EncoderParameterValueTypeLong = 1)
    NumPut("uint", 1, ep, 20)          ; 参数值数量
    NumPut("uint", Quality, ep, 24)     ; 质量值
    
    ; 保存位图
    E := DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "str", sOutput, "ptr", CLSID, "ptr", ep)
    return E
}

; ========== 获取编码器CLSID ==========
Gdip_GetEncoderClsid(sFormat) {
    ; 获取编码器数量
    DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &nCount:=0, "uint*", &nSize:=0)
    if !nCount || !nSize
        return 0
    
    ; 获取编码器信息
    ci := Buffer(nSize)
    DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "ptr", ci)
    
    ; 查找指定格式的编码器
    loop nCount {
        ; 计算当前编码器信息的偏移量
        offset := (A_Index - 1) * (48 + 7 * A_PtrSize)
        
        ; 获取MIME类型字符串长度
        mimeTypeLen := DllCall("lstrlenW", "ptr", NumGet(ci, offset, "ptr"), "int")
        if !mimeTypeLen
            continue
            
        ; 创建缓冲区并复制MIME类型字符串
        mimeTypeBuf := Buffer((mimeTypeLen + 1) * 2, 0)
        DllCall("lstrcpyW", "ptr", mimeTypeBuf, "ptr", NumGet(ci, offset, "ptr"))
        
        ; 比较MIME类型
        if (StrGet(mimeTypeBuf, "UTF-16") = sFormat) {
            ; 返回CLSID指针
            return NumGet(ci, offset + 32, "ptr")
        }
    }
    return 0
}

; ========== 释放位图 ==========
Gdip_DisposeImage(pBitmap) {
    return DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
} 