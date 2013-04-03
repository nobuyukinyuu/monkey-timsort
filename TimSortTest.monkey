Import mojo
Import timsort

Function Main:Int()
	New Test()
End Function

Class Test Extends App
	Field arr:Int[]
	Const ARR_LEN:Int = 64
	
	Field sorter:TimSort<Int>
		
	Method OnCreate:Int()
		SetUpdateRate 60
		
		'Populate the array.
		arr = arr.Resize(ARR_LEN)
		For Local i:Int = 0 Until ARR_LEN
			arr[i] = Rnd($FFFFF)
		Next

		sorter = New TimSort<Int>(arr, New IntComparator)
	End Method
	
	Method OnUpdate:Int()
		If KeyHit(KEY_SPACE)
			Local ms:Int = Millisecs()

			'TimSort<Int>.Sort(arr, New IntComparator)
			sorter.Sort(arr, New IntComparator)
			
			Local now:Int = Millisecs()
			now -= ms
			Print("Sort took " + now + " millisecs")
		End If
	End Method
	
	Method OnRender:Int()
		Cls
		For Local i:Int = 0 Until ARR_LEN
			DrawText(i + ": " + arr[i], 8, i * 16)
		Next
	End Method
End Class