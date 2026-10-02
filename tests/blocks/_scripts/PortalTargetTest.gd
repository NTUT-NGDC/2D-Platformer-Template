extends Node2D

# 手動驗證用：Portal 的 pair 指定傳送門以外的東西。
# Portal_ToSpot → TargetSpot（Marker2D，單向）；Portal_ToNode → PlainNode（普通 Node，沒有位置）；Portal_Empty 沒設 pair。

func _ready() -> void:
	$Portal_ToSpot.teleported.connect(func(_b): print("[測試] Portal_ToSpot：傳到 TargetSpot 了"))
	print("[測試] 先看編輯器：三座傳送門都有黃色驚嘆號，滑過去各自說明（不是傳送門／沒有位置／沒設目的地）；")
	print("[測試]   Portal_ToSpot 有一條紫色細虛線連到右上方的 TargetSpot")
	print("[測試] 開場輸出面板有三則 [傳送門] 警告")
	print("[測試] 走進 Portal_ToSpot：被傳到右上方 TargetSpot 的位置掉下來；走回 TargetSpot 那裡不會被傳回來（單向）")
	print("[測試] 走進 Portal_ToNode、Portal_Empty：不會傳送")
	print("[測試] 另外開 tests/blocks/PortalTest.tscn：Portal_B 沒設 pair 但被 Portal_A 指到，不應該有黃色驚嘆號，來回傳送照舊")
