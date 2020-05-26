
.thumb

.macro blh to, reg
    ldr \reg, =\to
    mov lr, \reg
    .short 0xF800
.endm

.equ gProc_WorldMap, 0x08A3D748
.equ ProcFind, 0x08002E9C
.equ SetBgPosition, 0x0800148C
.equ Decompress, 0x08012F50
.equ CopyToPaletteBuffer, 0x08000DB8
.equ gGenericBuffer, 0x02020188
.equ gBg1MapBuffer, 0x020234A8
.equ BgMap_ApplyTsa, 0x080D74A0
.equ EnableBgSyncByMask, 0x08001FAC
.equ gProc_GmapRMUpdate, 0x08A3EAF0
.equ ProcStart, 0x08002C7C

.global LoadSmallWorldMap
.type LoadSmallWorldMap, %function
LoadSmallWorldMap: @ Autohook to 0x080C1FE0. r0 = parent proc? We're rewriting the function that seems to load the small world map.
@ We'd like to allow for a specified number of palettes to load.
push { r4, r5, lr }
mov r5, r0
ldr r0, =gProc_WorldMap
blh ProcFind, r1
ldr r0, [ r0, #0x44 ]
ldr r1, [ r0, #0x4C ]
add r1, r1, #0x31
ldrb r2, [ r1 ]
mov r0, #0xFB
and r0, r0, r2
strb r0, [ r1 ]
mov r0, #0x01
mov r1, #0x00
mov r2, #0x00
blh SetBgPosition, r3
ldr r0, =SmallWorldMap
mov r1, #0xC0
lsl r1, r1, #0x13
blh Decompress, r2
@ Everything above this is vanilla. Here's where some magic happens.
ldr r0, =SmallWorldMapPalette @ Palette to load.
mov r1, #0xA0 @ Offset to write to.
ldr r2, =gSmallWorldMapPaletteCount
ldrb r2, [ r2 ]
@cmp r2, #10
@blt CopyMainPalette
@	mov r2, #0x09 @ This is because something else is using the 10th palette we'd like to use. The one afterwards is free, though. We load to that later.
@CopyMainPalette:
lsl r2, r2, #0x05 @ Multiply size by 32.
blh CopyToPaletteBuffer, r3
/*ldr r2, =gSmallWorldMapPaletteCount
ldrb r2, [ r0 ]
cmp r2, #0x10
blt NoHighPalette
	@ All right. We need to write this 10th palette not to what would have been the 10th but to the one right after it.
	ldr r0, =SmallWorldMapPalette
	mov r1, #11 @ The palette we want is actually the 11th in our assembled palettes.
	lsl r1, r1, #0x05 @ r1 = 0x20 * 11 = 0x160
	add r0, r0, r1 @ r0 = our palette we want.
	add r1, r1, #0xA0 @ Convenient: Add 0xA0 to our offset we had in r1 before to get the buffer offset to write to.
	
NoHighPalette:*/
ldr r0, =SmallWorldMapTSA
ldr r4, =gGenericBuffer
mov r1, r4
blh Decompress, r2
ldr r0, =gBg1MapBuffer
mov r2, #0xA0
lsl r2, r2, #0x07
mov r1, r4
blh BgMap_ApplyTsa, r3
mov r0, #0x02
blh EnableBgSyncByMask, r1
ldr r0, =gProc_GmapRMUpdate
mov r1, r5
blh ProcStart, r2
pop { r4 - r5 }
pop { r0 }
bx r0

.equ Make6C_GMap_RM, 0x080C2420
.equ CallMapEventEngine, 0x0800D07C
.equ StartMapEventEngine, 0x0800D0B0
.equ ProcStartBlocking, 0x08002CE0
.equ gMemorySlot, 0x030004B8
.equ BreakProcLoop, 0x08002E94
.global StartSmallWorldMap
.type StartSmallWorldMap, %function
StartSmallWorldMap: @ r0 = parent proc (the event engine).
push { lr }
mov r1, r0
ldr r0, =WorldMapWrapperProc
blh ProcStartBlocking, r2
pop { r0 }
bx r0

.global WorldMapWrapperProcCallEvents
.type WorldMapWrapperProcCallEvents,%function
WorldMapWrapperProcCallEvents:
push { lr } @ I was successfully able to invoke the world map event engine with this! But... some things were a little messed up... text wouldn't load properly, and it would softlock sometimes.
ldr r0, =WorldMapEventTest
mov r1, #0x00
blh StartMapEventEngine, r2 @ CONFIRMED: Some world map events presuppose the existence of gProc_WorldMap! Invoking that proc before starting events seems to fix things.
pop { r0 }
bx r0

.global WorldMapWrapperProcAreEventsFinished
.type WorldMapWrapperProcAreEventsFinished, %function
WorldMapWrapperProcAreEventsFinished:
push { lr }
ldr r1, =gMemorySlot
ldr r1, [ r1, #0x2C ] @ Memory slot 0xB.
cmp r1, #0x00
beq EventsAreNotFinished
	blh BreakProcLoop, r1
EventsAreNotFinished:
pop { r0 }
bx r0

@ THIS was successful in blocking the event engine and showing the small world map. I don't think we invoked the WM event engine, though.
/*push { r4, lr } @ Wrapper for Make6C_GMap_RM (0x080C2420). r0 = parent proc (event engine).
mov r0, #0x00 @ X coord?
mov r1, #0x00 @ Y coord?
mov r2, #0x10 @ 0x01 = slow fade? No other values appear to do anything, but 0x10 is passed in as vanilla. Strange. The bitfield this writes to seems to get overwritten.
mov r3, #0x00 @ Proc to block. Blocks none if null. Passing in the event engine causes it to softlock looping through the proc cycle. todo investigate further.
blh Make6C_GMap_RM, r4
pop { r4 }
pop { r0 }
bx r0*/
