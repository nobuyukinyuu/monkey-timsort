'Testing suite for the various algorithm speeds, as implemented in Monkey.
'This test utilizes diddy's quicksort routine merely for comparison.
'it is not necessary to implement quicksort if you only want to use timsort.
'		-Nobuyuki  (nobu@subsoap.com)  05 Apr 2013

'WARNING: Certain sorts (eg: Binary sort) may take a LONG time, or even lock up/crash
'         depending on the number of elements to be sorted. Use care when testing!

'If you wish to use TimSort in your own projects, the only files you need are:
' timsort.monkey, arrays.monkey, and comparator.monkey.

#GLFW_WINDOW_TITLE="TimSortTest"
#ANDROID_APP_LABEL="TimSortTest"
#ANDROID_APP_PACKAGE="com.test.timsort"

Import mojo
Import timsort
Import quicksortTest

Function Main:Int()
	New Test()
End Function

Class Test Extends App
	Field arr:Int[]
	Const ARR_LEN:Int = 50000
	Field SEED:Int = 1234   'Set this seed to produce predictable random arrays
			
	Field SortType:String[] =["TimSort", "Quicksort", "Binary Sort"]
	Field CurrentSortType:Int = 0
	
	Field d:PrintBuffer = New PrintBuffer(10)  'used to display debug messages
	
	Method OnCreate:Int()
		SetUpdateRate 60

		arr = arr.Resize(ARR_LEN)
		
		'Populate the array.
		PopulateArray()
	End Method

	'Summary:  Populates the array with random values.
	Method PopulateArray:Void()
		Seed = SEED

		For Local i:Int = 0 Until ARR_LEN
			arr[i] = Rnd(-$FF, $FFFFF)
		Next
	End Method
		
	Method OnUpdate:Int()
		'Get touches
		Local Touches:Int
		If TouchHit(3)
			Touches = 4
		ElseIf TouchHit(2)
			Touches = 3
		ElseIf TouchHit(1)
			Touches = 2
		ElseIf TouchHit(0)
			Touches = 1
		Else
			Touches = 0
		End If

		If KeyHit(KEY_F12) or Touches = 4  'Change seed
			SEED = Millisecs(); Seed = SEED
		End If
			
		If KeyHit(KEY_ENTER) or Touches = 3  'Sort
			Local ms:Int = Millisecs()

			Select CurrentSortType
			Case 0 'TimSort
				TimSort<Int>.Sort(arr, New IntComparator())

			Case 1 'diddy Quicksort
				'quicksort works on boxed ints. We need to create an array of those first.
				Local arr2:Object[arr.Length]
				For Local i:Int = 0 Until arr2.Length
					arr2[i] = New IntObject(arr[i])
				Next
				QuickSort(arr2, 0, arr.Length - 1, DEFAULT_COMPARATOR)
				'Now, unbox the array.
				For Local i:Int = 0 Until arr2.Length
					arr[i] = IntObject(arr2[i]).value
				Next

			Case 2 'Binary Sort
				TimSort<Int>.binarySort(arr, 0, arr.Length, 0, New IntComparator())
			End Select
			
			Local now:Int = Millisecs()
			now -= ms
			Local printMsg:String = SortType[CurrentSortType] + " took " + now + " millisecs"
			d.Print(printMsg); Print(printMsg)
			
		End If

		
		If KeyHit(KEY_BACKSPACE) or Touches = 2  'Randomize
			PopulateArray()
		End If
				
		If KeyHit(KEY_SPACE) or Touches = 1 'Change algo
			CurrentSortType += 1
			If CurrentSortType >= SortType.Length Then CurrentSortType = 0
		End If
				
		If KeyHit(KEY_CLOSE) or KeyHit(KEY_ESCAPE) Then Error("")
	End Method
	
	Method OnRender:Int()
		Cls
		
		DrawText("Spacebar / 3 touches: Sort List", 8, 8)
		DrawText("Backspace: Randomize List / 2 touches", 8, 24)
		DrawText("Enter / 1 touch: Change sorting algorithm", 8, 40)
		DrawText("F12 / 4 touches:  Change randomizer seed (currently " + SEED + ")", 8, 56)
		
		DrawText("Current sorting algo: " + SortType[CurrentSortType], 8, 80)
		If CurrentSortType = 2 Then DrawText("WARNING: BinarySort may crash the application on large sorts", 8, 96)
		
		For Local i:Int = 0 To Min(arr.Length - 1, 32)
			DrawText(i + ": " + arr[i], DeviceWidth() -8, i * 16, 1)
		Next
		
		d.Render(16, 320)
	End Method
End Class



'Summary:  A class to display a few lines of data
Class PrintBuffer
	Field size:Int = 5
	Field lines:= New StringList
	Field numLines:Int  'number of lines in buffer
		
	Method New(size:Int)
		Self.size = Max(3, size)
	End Method
	
	'Summary: Adds a line to the print buffer
	Method Print:Void(message:String)
		lines.AddLast(message)
		numLines += 1
		If numLines > size Then lines.RemoveFirst()
	End Method
	
	'Summary: Shows buffer
	Method Render:Void(x:Float, y:Float)
		SetAlpha(0.1)
		DrawRect(x - 4, y, 8, GetFont().Height * size)  'indicator box
		SetAlpha(1)
	
		Local i:Int  'iterator
		For Local l:String = EachIn lines
			DrawText(l, x, y + (i * GetFont().Height))
			i += 1
		Next
	End Method
End Class