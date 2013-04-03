'Naive implementation of Java comparators
'Nobuyuki, 03 April 2013  (nobu@subsoap.com)

'Summary: Returns -1-1 based on sort values. Extend this and make your own comparators to whatever type you like.
Class Comparator<T>
	Function Compare:Int(lhs:T, rhs:T)
		Error("Comparator<T> can't be instantiated directly. Please extend the class and override this method.")
	End Function
End Class
Class IntComparator Extends Comparator<Int>
	Function Compare:Int(lhs:Int, rhs:Int)
		If lhs < rhs Then Return - 1
		Return lhs > rhs
	End Function
End Class