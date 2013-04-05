Import mojo
Import timsort

Function Main:Int()
	New Test()
End Function

Class Test Extends App
	Field arr:Int[]
	Const ARR_LEN:Int = 500000
			
	Method OnCreate:Int()
		SetUpdateRate 60
		
		'Populate the array.
		'arr = arr.Resize(ARR_LEN)
		'For Local i:Int = 0 Until ARR_LEN
		'	arr[i] = Rnd($FFFFF)
		'Next
		
		arr =[0, 29, 0, 6, 4, 3, 6, 2, 1]

	End Method
	
	Method OnUpdate:Int()
		If KeyHit(KEY_SPACE)
			Local ms:Int = Millisecs()

			'TimSort<Int>.Sort(arr, New IntComparator)
			TimSort<Int>.binarySort(arr, 0, arr.Length, 0, New IntComparator(True))
			
			Local now:Int = Millisecs()
			now -= ms
			Print("Sort took " + now + " millisecs")
		End If

		
		If KeyHit(KEY_ENTER)
			For Local i:Int = 0 Until arr.Length
				arr[i] = Rnd($FFFFF)
			Next			
		End If
				
		
		If KeyHit(KEY_CLOSE) or KeyHit(KEY_ESCAPE) Then Error("")
	End Method
	
	Method OnRender:Int()
		Cls
		
		DrawText("Spacebar: Sort List", 8, 8)
		DrawText("Enter: Randomize List", 8, 24)
		
		For Local i:Int = 0 To Min(arr.Length - 1, 32)
			DrawText(i + ": " + arr[i], DeviceWidth() -8, i * 16, 1)
		Next
	End Method
End Class