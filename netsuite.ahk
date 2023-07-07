CoordMode, Mouse, Screen  ; Set mouse commands to use screen coordinates
CoordMode, Pixel, Screen  ; Set colour commands to use screen pixels

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

skipKey := "s" ;
resetKey := "r" ;
multipleKey := "m" ;
otherKey := "o"
stop := 0

; ---- Value Coordinates for the screen - Change these! ----

global magnifierX := 1878 ;
global magnifierY := 192 ;

global binSearchBarX := 1307 ;
global binSearchBarY := 226 ;

firstBinX := 1027 ;
firstBinY := 341 ;

global SOInbetweenX := 1073 ;
global SOInbetweenY := 407 ; 

global searchBarX := 400 ;
global searchBarY := 140 ;

relatedRecordsX := 374 ;
relatedRecordsY := 600 ;

global startingRecordDateX := 52 ; 
global startingRecordDateY := 697 ; 
global distanceBetweenRecords := 21 ; 

global startingRecordNumberX := 321 ; 
global startingRecordNumberStatusX := 458 ;

backButtonX := 991 ;
backButtonY := 1004 ;

markButtonX := 200 ;
markButtonY := 265 ;

shippedX := 200 ;
shippedY := 320 ;

sendCloudX := 835 ; 
sendCloudY := 558 ;

confirmBarX := 450  ; 
confirmBarY := 250  ; 
confirmBarColour := "0xD7FCCF"  ; 

printConfirmX := 340 ;
printConfirmY := 1000 ;
printConfirmColour := "0x525659" ;

binContentX := 1070 ; maybe set?
binContentY := 334 ; maybe set?
binContentColour := "0xEFF1F5" ; maybe set?

yellowIFX := 54 ; need to set!
yellowIFY := 255 ; need to set!
yellowIFColour := "0xEDA133" ; need to set!

memoX := 508 ; need to set!
memoY := 525 ; need to set!

; -- alternate flow variables
secondBinBtnX := 1324 ; need to set!
secondBinBtnY := 674 ; need to set!

editBtnX := 64 ; need to set!
editBtnY := 332 ; need to set!

; TODO, need additional color checking, probably...
; parcelQuanityX := 454; need to set!
; parcelQuantityY := 892; need to set!

; The starting hotkay to start this routine
!^F2:: 

; ---- End of variables ----

Loop
{
    Loop
    {
        TrayTip, Scan bin, and then press enter
        waitForEnter()
        ; stop if needed
        if (stop)
            break
        
        Sleep, 100
        Click, %firstBinX%, %firstBinY%

        ; load bin contents
        waitForColour(binContentX, binContentY, binContentColour)

        ; find suitable SO record and arrive at that page
        stickerCnt := findSuitableSORecord()
        if (stickerCnt == 0)
            break

        zilverID := getZilverID()

        ; click related records
        Sleep, 100 ;
        Click, %relatedRecordsX%, %relatedRecordsY%

        Sleep, 100
        if (!findAndClickValidIFRow())
        {
            TrayTip, Check status, to continue running press 'enter'
            waitForEnter()
        }

        ; sneakily store the Zilver ID on the clipboard
        clipboard := zilverID

        TrayTip, loading IF, 
        waitForColour(yellowIFX, yellowIFY, yellowIFColour)

        ; Multiple stickers?
        if (stickerCnt > 1) 
        {
            TrayTip, Setup sticker yourself, waiting for green bar...
            Click, %editBtnX%, %editBtnY%

            ; needs testing still, otherwise do waitForEnter()
            waitForColour(confirmBarX, confirmBarY, confirmBarColour) 
            Click %shippedX%, %shippedY% ; the bar moved due to the edit...
        }
        else 
        {
            Click %markButtonX%, %markButtonY% ;
        }

        ; Loop until packet is sucessfully packed
        waitForColour(confirmBarX, confirmBarY, confirmBarColour)
        Sleep, 500 ; The bar moves ...

        ; Try to print by sweeping the area with clicks
        Click %sendCloudX%, %sendCloudY%

        ; timing should be conistent here, as it is just the pc loading
        waitForEnterOrTimeout(1)

        PixelGetColor, color, %printConfirmX%, %printConfirmY%, RGB

        ; actually not on correct page...
        if (color != printConfirmColour)
        {
            TrayTip, Zilver detected - code already copied - Quitting now
            Click, %editBtnX%, %editBtnY%
            stop = true
            break ; break to save the world from this madness
        }
        
        Send, ^p ;      enter print menu
        Sleep, 300 ;
        Send, {Enter} ; print it
        Sleep, 1500 ;
        Send, {Enter} ; skip error (prob not there)
        Sleep, 400 ;
        Send, ^w ;      close the opened tab

        Sleep 400 ;

        Click %shippedX%, %shippedY% ;

        highlightSearch()

        ; proceed to then next order
    }
    ; quit entire program, mostly only used during Zilver moments
    if (stop)
        break
}
return

findSuitableSORecord()
{
    global skipKey, resetKey, otherKey, multipleKey
    copyAndSearchForSO()
    Loop
    {
        TrayTip, Check products, and then press enter or 's' if products are wrong or 'o' to select the other SO in the bin or 'r' if the copy went wrong
        ; Wait until the scanner checked the products in the list... or quits
        Input, pressed, L1

        ; Products missing, or wrong counts
        if (pressed == skipKey)
        {
            highlightSearch()
            return 0
        }

        if (pressed == resetKey)
        {
            copyAndSearchForSO()
            continue
        }

        ; select amount of stickers in second prompt
        if (pressed == multipleKey)
        {
            ; TODO
            ;Input, stickerCnt, L1
            ;TrayTip, Type the amount of sticker needed
            ;return stickerCnt
            return 2
        }

        ; wrong SO number, so need to select second one in bin
        if (pressed == otherKey)
        {
            selectSecondSO()
            continue
        }
        return 1
    }
}

; wait forever until enter is pressed
waitForEnter() 
{
    global stop , skipKey
    ; Wait until the whole thing is scanned
    Loop
    {
        Input, key, V, {Enter}
        if errorlevel = EndKey:Enter
            break
        else if key = skipKey
        {
            stop := 1
            break
        }
    }
}

; wait until the time runs out or enter is clicked    
waitForEnterOrTimeout(timeoutSeconds)
{
    ; Wait until the whole thing is scanned or until timeout
    Input, key, V T%timeoutSeconds%, {Enter}

    return key
}

copyAndSearch()
{
    global searchBarX, searchBar
    Send, ^c
    Sleep, 1
    Click %searchBarX%, %searchBarY%
    ClipWait, 1
    Send, ^v
    Sleep, 1 ;
    Send, {Enter}
}

selectSecondSO()
{
    global SOInbetweenX, SOInbetweenY, secondBinBtnX, secondBinBtnY

    Clipboard := "" ; Empty the clipboard

    ; Highlight the SO code from the mobile emulator again
    Click, %SOInbetweenX%, %SOInbetweenY%,
    Sleep, 100
    Click, %SOInbetweenX%, %SOInbetweenY%,
    Sleep, 100
    Click, %SOInbetweenX%, %SOInbetweenY%,
    Sleep, 100

    ; experimental, select second row
    Click %secondBinBtnX%, %secondBinBtnY%
    Sleep, 100
    ; Copy the SO number and search for it
    copyAndSearch()
}


copyAndSearchForSO()
{
    global SOInbetweenX, SOInbetweenY

    Clipboard := "" ; Empty the clipboard

    ; Highlight the SO code from the mobile emulator
    Click, %SOInbetweenX%, %SOInbetweenY%
    Sleep, 100
    Click, %SOInbetweenX%, %SOInbetweenY%
    Sleep, 100
    Click, %SOInbetweenX%, %SOInbetweenY%
    Sleep, 100

    ; Copy the SO number and search for it
    copyAndSearch()
}

; wait until the pixel at x, y show the target colour
waitForColour(pixelX, pixelY, targetColour)
{
    Loop
    {
        PixelGetColor, newColour, %pixelX%, %pixelY%, RGB
        if (newColour == targetColour)
            break  ; If the pixel color matches the target color, break the loop
        Sleep, 100  ; Sleep for a short time before checking again to prevent high CPU usage
    }
}

highlightSearch()
{
    global magnifierX, magnifierY, binSearchBarX, binSearchBarY, backButtonX, backButtonY

    ; already go back to the previous screen, so it can load...
    Click %backButtonX%, %backButtonY%
    Sleep, 800
    ; Hihglight the bin search bar again
    Click, %magnifierX%, %magnifierY%
    Sleep, 100 ;
    Click, %binSearchBarX%, %binSearchBarY%
}

; click the target and above and below the target with the offset as many times as numTries
sweepClick(targetX, targetY, numTries := 3, offset := 5)
{
    Loop, %numTries%
    {
        ClickY := targetY - offset + (A_Index - 1) * (offset * 2 / (numTries - 1)) 
        Click, %targetX%, %ClickY%
        Sleep, 100  ; Add a small delay between each click to not overload the system
    }
}

retrieveAndProcessText(targetX, targetY)
{
    Clipboard := "" ; Empty the clipboard

    ; Double-click at the specified coordinates to select the text
    Click, %targetX%, %targetY%, 3

    ; Copy the selected text to the clipboard
    Send, ^c

    ; Wait for the clipboard to contain data
    ClipWait, 1
    if ErrorLevel
    {
        MsgBox, Failed to copy data to the clipboard.
        return
    }

    ; Process the clipboard contents (replace this with your actual processing code)
    return Clipboard
}


findAndClickValidIFRow()
{
    global startingRecordDateX, startingRecordDateY, startingRecordNumberX, startingRecordNumberStatusX, distanceBetweenRecords
    ; Initialize the variables
    suitableRows := []
    prevNumber := ""

    Loop
    {
        ; Calculate the current Y-coordinate for this row
        currentY := startingRecordDateY + ((A_Index - 1) * distanceBetweenRecords)

        ; Copy and check the 'number' field
        currentNumber := retrieveAndProcessText(startingRecordNumberX, currentY)

        ; Break the loop if the copied record is the same as the previous one
        if (currentNumber == prevNumber || InStr(currentNumber, "Action"))
            break

        ; Copy and check the 'status' field
        currentStatus := retrieveAndProcessText(startingRecordNumberStatusX, currentY)

        ; If the 'number' starts with "IF" and the 'status' is "Picked", store this row
        if (InStr(currentNumber, "IF") && InStr(currentStatus, "Picked"))
            suitableRows.Push({number: currentNumber, dateX: startingRecordDateX, dateY: currentY})

        ; Update the previous 'number' and 'status' for the next iteration
        prevNumber := currentNumber
    }

    ; If no suitable record is found, display a notification
    if (suitableRows.Length() == 0)
    {
        MsgBox, No suitable record found
        return false
    }
    ; If multiple suitable records are found, ask the user to choose one
    else if (suitableRows.Length() > 1)
    {
        ; MsgBox, Multiple suitable records found
        Input, userNumber, L1
        ; InputBox, userNumber, Choose a record, Type the 'IF' number of the record you want to choose.
        for index, record in suitableRows
        {
            num := record["number"]
            if (num == userNumber)
            {
                clickX := record["dateX"]
                clickY := record["dateY"]

                Click, %clickX%, %clickY%
                return false
            }
        }
    }
    ; If only one suitable record is found, click the date to go through the page automatically
    else
    {
        suitableRow := suitableRows[1]
        clickX := suitableRow["dateX"]
        clickY := suitableRow["dateY"]

        Click, %clickX%, %clickY%
    }
    return true
}

getZilverID()
{
    global memoX, memoY
    Sleep, 100
    memo := retrieveAndProcessText(memoX, memoY)

    if (RegExMatch(memo, "\d+$", match))
    {
        return match
    }
    return ""
}
