'This is a testing version of Quicksort only.   -nobu
'The code was taken from the Diddy framework.  http://code.google.com/p/diddy/

#Rem
	summary: IComparable
	Allows developers to sort a collection without using a Comparator.  Each class is responsible
	for providing its own logic to determine how it should be sorted.
#End
Interface IComparable
	Method Compare:Int(o:Object)
	Method Equals:Bool(o:Object)
End

#Rem
	summary:IComparator
	This is a way For developers To provide a custom comparison Method For sorting lists.
	It's sort of like a function pointer.
#End
Class IComparator Abstract
' Abstract
	Method Compare:Int(o1:Object, o2:Object) Abstract
	
' Methods
	Method Equals:Bool(o1:Object, o2:Object)
		Return o1 = o2 Or Compare(o1, o2) = 0
	End
	
	Method HashCode:Int(o:Object)
		Return 0
	End
End

#Rem
	summary: DefaultComparator
	Implements an IComparator to handle primitive wrappers and strings.
#End
Global DEFAULT_COMPARATOR:DefaultComparator = New DefaultComparator
Class DefaultComparator Extends IComparator
' Methods
	'summary: Overrides IComparator
	Method Compare:Int(o1:Object, o2:Object)
		If IntObject(o1) <> Null And IntObject(o2) <> Null Then
			If IntObject(o1).value < IntObject(o2).value Then Return -1
			If IntObject(o1).value > IntObject(o2).value Then Return 1
			Return 0
		ElseIf FloatObject(o1) <> Null And FloatObject(o2) <> Null Then
			If FloatObject(o1).value < FloatObject(o2).value Then Return -1
			If FloatObject(o1).value > FloatObject(o2).value Then Return 1
			Return 0
		ElseIf StringObject(o1) <> Null And StringObject(o2) <> Null Then
			If StringObject(o1).value < StringObject(o2).value Then Return -1
			If StringObject(o1).value > StringObject(o2).value Then Return 1
			Return 0
		End
		If o1 = o2 Then Return 0
		If o1 = Null Then Return -1
		If o2 = Null Then Return 1
		Return 0 ' don't know what to do!
	End
	
	'summary: Overrides IComparator
	Method Equals:Bool(o1:Object, o2:Object)
		If IntObject(o1) <> Null And IntObject(o2) <> Null Then
			Return IntObject(o1).value = IntObject(o2).value
		ElseIf FloatObject(o1) <> Null And FloatObject(o2) <> Null Then
			Return FloatObject(o1).value = FloatObject(o2).value
		ElseIf StringObject(o1) <> Null And StringObject(o2) <> Null Then
			Return StringObject(o1).value = StringObject(o2).value
		End
		Return o1 = o2
	End
End


'summary: QuickSort
Function QuickSort:Void(arr:Object[], left:Int, right:Int, comp:IComparator, reverse:Bool = False)
	If right > left Then
		Local pivotIndex:Int = left + (right-left)/2
		Local pivotNewIndex:Int = QuickSortPartition(arr, left, right, pivotIndex, comp, reverse)
		QuickSort(arr, left, pivotNewIndex - 1, comp, reverse)
		QuickSort(arr, pivotNewIndex + 1, right, comp, reverse)
	End
End

'summary: QuickSortPartition
Function QuickSortPartition:Int(arr:Object[], left:Int, right:Int, pivotIndex:Int, comp:IComparator, reverse:Bool = False)
	Local pivotValue:Object = arr[pivotIndex]
	arr[pivotIndex] = arr[right]
	arr[right] = pivotValue
	Local storeIndex:Int = left, val:Object
	For Local i:Int = left Until right
		If IComparable(arr[i]) <> Null Then
			If Not reverse And IComparable(arr[i]).Compare(pivotValue) <= 0 Or reverse And IComparable(arr[i]).Compare(pivotValue) >= 0 Then
				val = arr[i]
				arr[i] = arr[storeIndex]
				arr[storeIndex] = val
				storeIndex += 1
			End
		Else
			If Not reverse And comp.Compare(arr[i], pivotValue) <= 0 Or reverse And comp.Compare(arr[i], pivotValue) >= 0 Then
				val = arr[i]
				arr[i] = arr[storeIndex]
				arr[storeIndex] = val
				storeIndex += 1
			End
		End
	Next
	val = arr[storeIndex]
	arr[storeIndex] = arr[right]
	arr[right] = val
	Return storeIndex
End
