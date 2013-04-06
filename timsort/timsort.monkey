#Rem
	TimSort for Monkey
	2013 Nobuyuki ( nobu@subsoap.com )
	
	Based on code from these sources:
	https://github.com/Scipion/interesting-javascript-codes/blob/master/timsort.js
	http://hg.openjdk.java.net/jdk7/tl/jdk/file/tip/src/share/classes/java/util/TimSort.java
	
	As a result, this code is probably GPLv3. I'm not a lawyer, you can figure it out!
#End

Import arrays
Import comparator

Class TimSort<T>
    #Rem
     * This is the minimum sized sequence that will be merged.  Shorter
     * sequences will be lengthened by calling binarySort.  If the entire
     * array is less than this length, no merges will be performed.
     *
     * This constant should be a power of two.  It was 64 in Tim Peter's C
     * implementation, but 32 was empirically determined to work better in
     * this implementation.  In the unlikely event that you set this constant
     * to be a number that's not a power of two, you'll need to change the
     * {@link #minRunLength} computation.
     *
     * If you decrease this constant, you must change the stackLen
     * computation in the TimSort constructor, or you risk an
     * ArrayOutOfBounds exception.  See listsort.txt for a discussion
     * of the minimum stack length required as a function of the length
     * of the array being sorted and the minimum merge sequence length.
    #End
Private
    Const MIN_MERGE:Int = 32

    
    ' The array being sorted.
     Field a:T[]

    ' The comparator for this sort.
    Field c:Comparator<T>

'    /**
'     * When we get into galloping mode, we stay there until both runs win less
'     * often than MIN_GALLOP consecutive times.
'     */
    Const MIN_GALLOP:Int = 7

'    /**
'     * This controls when we get *into* galloping mode.  It is initialized
'     * to MIN_GALLOP.  The mergeLo and mergeHi methods nudge it higher for
'     * random data, and lower for highly structured data.
'     */
    Field minGallop:int = MIN_GALLOP

'    /**
'     * Maximum initial size of tmp array, which is used for merging.  The array
'     * can grow to accommodate demand.
'     *
'     * Unlike Tim's original C version, we do not allocate this much storage
'     * when sorting smaller arrays.  This change was required for performance.
'     */
    Const INITIAL_TMP_STORAGE_LENGTH:Int = 256

'    /**
'     * Temp storage for merges.
'     */
    Field tmp:T[] ' Actual runtime type will be Object[], regardless of T

'    /**
'     * A stack of pending runs yet to be merged.  Run i starts at
'     * address base[i] and extends for len[i] elements.  It's always
'     * true (so long as the indices are in bounds) that:
'     *
'     *     runBase[i] + runLen[i] == runBase[i + 1]
'     *
'     * so we could cut the storage for this, but it's a minor amount,
'     * and keeping all the info explicit simplifies the code.
'     */
    Field stackSize:Int = 0  'Number of pending runs on stack
    Field runBase:int[]
    Field runLen:int[]

'    /**
'     * Creates a TimSort instance to maintain the state of an ongoing sort.
'     *
'     * @param a the array to be sorted
'     * @param c the comparator to determine the order of the sort
'     */

    Method New(a:T[], c:Comparator<T>)
        Self.a = a
        Self.c = c

        ' Allocate temp storage (which may be increased later if necessary)
        Local len:Int = a.Length

		'T[] newArray = (T[]) new Object[len < 2 * INITIAL_TMP_STORAGE_LENGTH ?
    	'                              len >>> 1 : INITIAL_TMP_STORAGE_LENGTH];
		Local newArray:T[]
		If len < 2 * INITIAL_TMP_STORAGE_LENGTH Then
			newArray = newArray.Resize(len Shr 1)
		Else
			newArray = newArray.Resize(INITIAL_TMP_STORAGE_LENGTH)
		End If
		
        tmp = newArray

#Rem
         * Allocate runs-to-be-merged stack (which cannot be expanded).  The
         * stack length requirements are described in listsort.txt.  The C
         * version always uses the same stack length (85), but this was
         * measured to be too expensive when sorting "mid-sized" arrays (e.g.,
         * 100 elements) in Java.  Therefore, we use smaller (but sufficiently
         * large) stack lengths for smaller arrays.  The "magic numbers" in the
         * computation below must be changed if MIN_MERGE is decreased.  See
         * the MIN_MERGE declaration above for more information.
#End
'        int stackLen = (len <    120  ?  5 :
'                        len <   1542  ? 10 :
'                        len < 119151  ? 19 : 40);
		Local stackLen:Int
		
		If len < 120 Then
				stackLen = 5
			ElseIf len < 1542
				stackLen = 10
			ElseIf len < 119151
				stackLen = 19
			Else; stackLen = 40
		End If

        runBase = New int[stackLen]
        runLen = New int[stackLen]
    End Method
	
'    /*
'     * The next two methods (which are package private and static) constitute
'     * the entire API of this class.  Each of these methods obeys the contract
'     * of the public method with the same signature in java.util.Arrays.
'     */
Public
    Function Sort:Void(a:T[], c:Comparator<T>)
        Sort(a, 0, a.Length, c)
    End Function

    Function Sort:Void(a:T[], lo:Int, hi:Int, c:Comparator<T>)
        If c = Null
            'Arrays.sort(a, lo, hi)
			Error("Array can't be sorted - elements aren't comparable")  'Hack until we have standard Array.sort -nobu
            Return
        End If

        rangeCheck(a.Length, lo, hi)
        Local nRemaining:Int = hi - lo

        If (nRemaining < 2) Then Return  ' Arrays of size 0 and 1 are always sorted

        ' If array is small, do a "mini-TimSort" with no merges
        If (nRemaining < MIN_MERGE) Then
            Local initRunLen:Int = countRunAndMakeAscending(a, lo, hi, c)
            binarySort(a, lo, hi, lo + initRunLen, c)
            Return
        End If

'        /**
'         * March over the array once, left to right, finding natural runs,
'         * extending short natural runs to minRun elements, and merging runs
'         * to maintain stack invariant.
'         */
        Local ts:TimSort<T> = New TimSort<T>(a, c)
        Local minRun:Int = minRunLength(nRemaining)

        Repeat
            ' Identify next run
            Local runLen:Int = countRunAndMakeAscending(a, lo, hi, c)

            ' If run is short, extend to min(minRun, nRemaining)
            If (runLen < minRun) Then
                Local force:Int; If nRemaining <= minRun Then force = nRemaining Else force = minRun
                binarySort(a, lo, lo + force, lo + runLen, c)
                runLen = force
            End If

            ' Push run onto pending-run stack, and maybe merge
            ts.pushRun(lo, runLen)
            ts.mergeCollapse()

            ' Advance to find next run
            lo += runLen
            nRemaining -= runLen
        Until nRemaining = 0

        ' Merge all remaining runs to complete sort
        #If CONFIG="debug"
		If lo <> hi Then Error("lo <> hi") 'assert lo == hi;
		#End

        ts.mergeForceCollapse()

        #If CONFIG="debug"
		If ts.stackSize <> 1 Then Error("ts.stackSize <> 1") 'assert ts.stackSize == 1;
		#End
    End Function

'    /**
'     * Sorts the specified portion of the specified array using a binary
'     * insertion sort.  This is the best method for sorting small numbers
'     * of elements.  It requires O(n log n) compares, but O(n^2) data
'     * movement (worst case).
'     *
'     * If the initial part of the specified range is already sorted,
'     * this method can take advantage of it: the method assumes that the
'     * elements from index {@code lo}, inclusive, to {@code start},
'     * exclusive are already sorted.
'     *
'     * @param a the array in which a range is to be sorted
'     * @param lo the index of the first element in the range to be sorted
'     * @param hi the index after the last element in the range to be sorted
'     * @param start the index of the first element in the range that is
'     *        not already known to be sorted (@code lo <= start <= hi}
'     * @param c comparator to used for the sort
'     */
'    @SuppressWarnings("fallthrough")

    Function binarySort:Void(a:T[], lo:Int, hi:Int, start:Int, c:Comparator<T>)
        #If CONFIG="debug"
		'assert lo <= start & & start <= hi;
		If Not (lo <= start And start <= hi) Then Error("binarySort: start index out of range")
		'Print("binarySort: " +lo + " to " + hi + ", start: " + start)
		#End
		
        If (start = lo) Then start += 1
        'For(; start < hi; start ++) {
		'While start < hi
		For start = start Until hi
            Local pivot:T = a[start]

            ' Set left (and right) to the index where a[start] (pivot) belongs
            Local left:Int = lo
            Local right:Int = start
            #If CONFIG="debug"
			If Not (left <= right) Then Error("binarySort: left > right") 'assert left <= right;
			#End 

'            /*
'             * Invariants:
'             *   pivot >= all in [lo, left).
'             *   pivot <  all in [right, start).
'             */

            While (left < right)
                Local mid:Int = (left + right) shr 1  'This should really be unsigned shift right  -nobu
                If (c.Compare(pivot, a[mid]) < 0) Then
                    right = mid
                else
                    left = mid + 1
				End If
            Wend
			#If CONFIG="debug"
            If left <> right Then Error("binarySort: left <> right") 'assert left == right;
			#End

'            /*
'             * The invariants still hold: pivot >= all in [lo, left) and
'             * pivot < all in [left, start), so pivot belongs at left.  Note
'             * that if there are elements equal to pivot, left points to the
'             * first slot after them -- that's why this sort is stable.
'             * Slide elements over to make room to make room for pivot.
'             */
            Local n:Int = start - left  'The number of elements To move
           
		   
		    ' "Switch is just an optimization for arraycopy in default case"

		'Wow!  Something weird happens with Select Case and Generics, so let's replace it with Ifs... 
		'Note that the original Switch code exhibited fall-thru behavior, which Monkey can't do,
		'so this particular block of code is different.  -nobu
            If n = 2 Then	a[left + 2] = a[left + 1]
            If n = 1
				a[left + 1] = a[left]
            	'Exit
            Else
				Arrays<T>.Copy(a, left, a, left + 1, n) 'System.arraycopy(a, left, a, left + 1, n)
			End If

            a[left] = pivot

		'start += 1
        Next 'End While
    End Function
  Private
'    /**
'     * Returns the length of the run beginning at the specified position in
'     * the specified array and reverses the run if it is descending (ensuring
'     * that the run will always be ascending when the method returns).
'     *
'     * A run is the longest ascending sequence with:
'     *
'     *    a[lo] <= a[lo + 1] <= a[lo + 2] <= ...
'     *
'     * or the longest descending sequence with:
'     *
'     *    a[lo] >  a[lo + 1] >  a[lo + 2] >  ...
'     *
'     * For its intended use in a stable mergesort, the strictness of the
'     * definition of "descending" is needed so that the call can safely
'     * reverse a descending sequence without violating stability.
'     *
'     * @param a the array in which a run is to be counted and possibly reversed
'     * @param lo index of the first element in the run
'     * @param hi index after the last element that may be contained in the run.
'              It is required that @code{lo < hi}.
'     * @param c the comparator to used for the sort
'     * @return  the length of the run beginning at the specified position in
'     *          the specified array
'     */
    Function countRunAndMakeAscending:Int(a:T[], lo:Int, hi:Int, c:Comparator<T>)
        #If CONFIG="debug"
			If Not (lo < hi) Then Error("countRunAndMakeAscending: low >= hi") 'assert lo < hi;
		#End
		
        Local runHi:Int = lo + 1
        If runHi = hi Then Return 1

        ' Find end of run, and reverse range if descending
        If (c.Compare(a[runHi], a[lo]) < 0)  ' Descending
			runHi += 1
            While (runHi < hi And c.Compare(a[runHi], a[runHi - 1]) < 0)
                runHi += 1
			Wend
            reverseRange(a, lo, runHi)
        Else                                     ' Ascending
            While (runHi < hi And c.Compare(a[runHi], a[runHi - 1]) >= 0)
                runHi += 1
			Wend
        End If

        Return runHi - lo
    End Function

'    /**
'     * Reverse the specified range of the specified array.
'     *
'     * @param a the array in which a range is to be reversed
'     * @param lo the index of the first element in the range to be reversed
'     * @param hi the index after the last element in the range to be reversed
'     */
    Function reverseRange:Void(a:T[], lo:Int, hi:Int)
        hi -= 1
        While (lo < hi)
            Local t:T = a[lo]
            a[lo] = a[hi]; lo += 1    ' a[lo++] = a[hi];
            a[hi] = t; hi -= 1        ' a[hi--] = t;
        Wend
    End Function

'    /**
'     * Returns the minimum acceptable run length for an array of the specified
'     * length. Natural runs shorter than this will be extended with
'     * {@link #binarySort}.
'     *
'     * Roughly speaking, the computation is:
'     *
'     *  If n < MIN_MERGE, return n (it's too small to bother with fancy stuff).
'     *  Else if n is an exact power of 2, return MIN_MERGE/2.
'     *  Else return an int k, MIN_MERGE/2 <= k <= MIN_MERGE, such that n/k
'     *   is close to, but strictly less than, an exact power of 2.
'     *
'     * For the rationale, see listsort.txt.
'     *
'     * @param n the length of the array to be sorted
'     * @return the length of the minimum run to be merged
'     */
    Function minRunLength:Int(n:Int)
		#If CONFIG="debug"
	        If Not (n >= 0) Then Error("minRunLength(n) must be >0") 'assert n >= 0;
		#End
		
        Local r:Int = 0      ' Becomes 1 if any 1 bits are shifted off
        While (n >= MIN_MERGE)
            r = r | (n & 1)
			
            n = n Shr 1
        Wend
        Return n + r
    End Function

'    /**
'     * Pushes the specified run onto the pending-run stack.
'     *
'     * @param runBase index of the first element in the run
'     * @param runLen  the number of elements in the run
'     */
   Method pushRun:Void(runBase:Int, runLen:Int)
        Self.runBase[stackSize] = runBase
        Self.runLen[stackSize] = runLen
        stackSize += 1
    End Method

'    /**
'     * Examines the stack of runs waiting to be merged and merges adjacent runs
'     * until the stack invariants are reestablished:
'     *
'     *     1. runLen[i - 3] > runLen[i - 2] + runLen[i - 1]
'     *     2. runLen[i - 2] > runLen[i - 1]
'     *
'     * This method is called each time a new run is pushed onto the stack,
'     * so the invariants are guaranteed to hold for i < stackSize upon
'     * entry to the method.
'     */
    Method mergeCollapse:Void()
        While (stackSize > 1)
            Local n:Int = stackSize - 2
            If (n > 0 And runLen[n - 1] <= runLen[n] + runLen[n + 1]) Then
                If (runLen[n - 1] < runLen[n + 1]) Then n -= 1
                mergeAt(n)
            ElseIf(runLen[n] <= runLen[n + 1])
                mergeAt(n)
            Else
                Exit ' Invariant is established
            End If
        Wend
    End Method

'    /**
'     * Merges all runs on the stack until only one remains.  This method is
'     * called once, to complete the sort.
'     */
    Method mergeForceCollapse:Void()
        While (stackSize > 1)
            Local n:Int = stackSize - 2
            If (n > 0 And runLen[n - 1] < runLen[n + 1]) Then n -= 1
            mergeAt(n)
        Wend
    End Method

'    /**
'     * Merges the two runs at stack indices i and i+1.  Run i must be
'     * the penultimate or antepenultimate run on the stack.  In other words,
'     * i must be equal to stackSize-2 or stackSize-3.
'     *
'     * @param i stack index of the first of the two runs to merge
'     */
    Method mergeAt:Void(i:Int)
        'assert stackSize >= 2;
        'assert i >= 0;
        'assert i == stackSize - 2 || i == stackSize - 3;
		#If CONFIG="debug"
			If stackSize < 2 Then Error("mergeAt: stackSize < 2")
			If i < 0 Then Error("mergeAt: i < 0")
			If Not ( (i = stackSize - 2) Or (i = stackSize - 3)) Then Error("mergeAt: Run i not penultimate")
		#End 
		
        Local base1:Int = runBase[i]
        Local len1:Int = runLen[i]
        Local base2:Int = runBase[i + 1]
        Local len2:Int = runLen[i + 1]

        'assert len1 > 0 && len2 > 0;
        'assert base1 + len1 == base2;
		#If CONFIG="debug"
			If Not (len1 > 0 And len2 > 0) Then Error("mergeAt: runLen <= 0")
			If Not (base1 + len1 = base2) Then Error("mergeAt:  base1 + len1 <> base2")
		#End 
'        /*
'         * Record the length of the combined runs; if i is the 3rd-last
'         * run now, also slide over the last run (which isn't involved
'         * in this merge).  The current run (i+1) goes away in any case.
'         */
        runLen[i] = len1 + len2
        If (i = stackSize - 3)
            runBase[i + 1] = runBase[i + 2]
            runLen[i + 1] = runLen[i + 2]
        End If
        stackSize -= 1

'        /*
'         * Find where the first element of run2 goes in run1. Prior elements
'         * in run1 can be ignored (because they're already in place).
'         */
        Local k:Int = gallopRight(a[base2], a, base1, len1, 0, c)
  		  #If CONFIG="debug"
			If k < 0 Then Error("mergeAt: k < 0") 'assert k >= 0;
		  #End 

        base1 += k
        len1 -= k
        If (len1 = 0) Then Return

'        /*
'         * Find where the last element of run1 goes in run2. Subsequent elements
'         * in run2 can be ignored (because they're already in place).
'         */
        len2 = gallopLeft(a[base1 + len1 - 1], a, base2, len2, len2 - 1, c)

 		  #If CONFIG="debug"
        	If len2 < 0 Then Error("mergeAt: len2 < 0") 'assert len2 >= 0;
		  #End
        If (len2 = 0) Then Return

        ' Merge remaining runs, using tmp array with min(len1, len2) elements
        If (len1 <= len2)
            mergeLo(base1, len1, base2, len2)
        Else
            mergeHi(base1, len1, base2, len2)
		End If
    End Method

'    /**
'     * Locates the position at which to insert the specified key into the
'     * specified sorted range; if the range contains an element equal to key,
'     * returns the index of the leftmost equal element.
'     *
'     * @param key the key whose insertion point to search for
'     * @param a the array in which to search
'     * @param base the index of the first element in the range
'     * @param len the length of the range; must be > 0
'     * @param hint the index at which to begin the search, 0 <= hint < n.
'     *     The closer hint is to the result, the faster this method will run.
'     * @param c the comparator used to order the range, and to search
'     * @return the int k,  0 <= k <= n such that a[b + k - 1] < key <= a[b + k],
'     *    pretending that a[b - 1] is minus infinity and a[b + n] is infinity.
'     *    In other words, key belongs at index b + k; or in other words,
'     *    the first k elements of a should precede key, and the last n - k
'     *    should follow it.
'     */
    Function gallopLeft:Int(key:T, a:T[], base:Int, len:Int, hint:Int, c:Comparator<T>)
        
		#If CONFIG="debug"
		'assert len > 0 && hint >= 0 && hint < len;
		If Not (len > 0 And hint >= 0 And hint < len) Then Error("gallopLeft: honk")
		#End 

		
		
        Local lastOfs:Int = 0
        Local ofs:Int = 1
        If (c.Compare(key, a[base + hint]) > 0)
            ' Gallop right until a[base+hint+lastOfs] < key <= a[base+hint+ofs]
            Local maxOfs:Int = len - hint
            While (ofs < maxOfs And c.Compare(key, a[base + hint + ofs]) > 0)
                lastOfs = ofs
                ofs = (ofs Shl 1) + 1

                If (ofs <= 0) Then ofs = maxOfs  ' int overflow                
            Wend
            If (ofs > maxOfs) Then ofs = maxOfs

            ' Make offsets relative to base
            lastOfs += hint
            ofs += hint
        Else  ' key <= a[base + hint]
            ' Gallop left until a[base+hint-ofs] < key <= a[base+hint-lastOfs]
            Local maxOfs:Int = hint + 1

            While (ofs < maxOfs And c.Compare(key, a[base + hint - ofs]) <= 0)
                lastOfs = ofs
                ofs = (ofs Shl 1) + 1
                If (ofs <= 0) Then ofs = maxOfs  ' int overflow
            Wend
            If (ofs > maxOfs) Then ofs = maxOfs

            ' Make offsets relative to base
            Local tmp:Int = lastOfs
            lastOfs = hint - ofs
            ofs = hint - tmp
        End If

		#If CONFIG="debug"
        'assert -1 <= lastOfs && lastOfs < ofs && ofs <= len;
		If Not (-1 <= lastOfs And lastOfs < ofs And ofs <= len) Then Error("gallopLeft: honk honk")
		#End

'        /*
'         * Now a[base+lastOfs] < key <= a[base+ofs], so key belongs somewhere
'         * to the right of lastOfs but no farther right than ofs.  Do a binary
'         * search, with invariant a[base + lastOfs - 1] < key <= a[base + ofs].
'         */
        lastOfs += 1
        While (lastOfs < ofs)
            Local m:Int = lastOfs + ( (ofs - lastOfs) Shr 1)  'Should use unsigned shift here  -nobu

            If (c.Compare(key, a[base + m]) > 0)
                lastOfs = m + 1  ' a[base + m] < key
            Else
                ofs = m          ' key <= a[base + m]
			End If
        Wend

		#If CONFIG="debug"
        'assert lastOfs == ofs;    ' so a[base + ofs - 1] < key <= a[base + ofs]
		If lastOfs <> ofs Then Error("gallopLeft: lastOfs <> ofs")
		#End
		
        Return ofs
    End Function

'    /**
'     * Like gallopLeft, except that if the range contains an element equal to
'     * key, gallopRight returns the index after the rightmost equal element.
'     *
'     * @param key the key whose insertion point to search for
'     * @param a the array in which to search
'     * @param base the index of the first element in the range
'     * @param len the length of the range; must be > 0
'     * @param hint the index at which to begin the search, 0 <= hint < n.
'     *     The closer hint is to the result, the faster this method will run.
'     * @param c the comparator used to order the range, and to search
'     * @return the int k,  0 <= k <= n such that a[b + k - 1] <= key < a[b + k]
'     */
    Function gallopRight:Int(key:T, a:T[], base:Int, len:Int, hint:Int, c:Comparator<T>)
		#If CONFIG="debug"
		'assert len > 0 && hint >= 0 && hint < len;
		If Not (len > 0 And hint >= 0 And hint < len) Then Error("gallopRight: honk")
		#End 

		
        Local ofs:Int = 1
        Local lastOfs:Int = 0
        If (c.Compare(key, a[base + hint]) < 0)
            ' Gallop left until a[b+hint - ofs] <= key < a[b+hint - lastOfs]
            Local maxOfs:Int = hint + 1
            While (ofs < maxOfs And c.Compare(key, a[base + hint - ofs]) < 0)
                lastOfs = ofs
                ofs = (ofs Shl 1) + 1
                If (ofs <= 0) Then ofs = maxOfs  ' int overflow
            Wend
            If (ofs > maxOfs) Then ofs = maxOfs

            ' Make offsets relative to b
            Local tmp:Int = lastOfs
            lastOfs = hint - ofs
            ofs = hint - tmp
         Else  ' a[b + hint] <= key
            ' Gallop right until a[b+hint + lastOfs] <= key < a[b+hint + ofs]
            Local maxOfs:Int = len - hint
			
            While (ofs < maxOfs And c.Compare(key, a[base + hint + ofs]) >= 0)
                lastOfs = ofs
                ofs = (ofs Shl 1) + 1
                If (ofs <= 0) Then ofs = maxOfs  ' int overflow
            Wend
            If (ofs > maxOfs) Then ofs = maxOfs

            ' Make offsets relative to b
            lastOfs += hint
            ofs += hint
        End If
		#If CONFIG="debug"
        'assert -1 <= lastOfs && lastOfs < ofs && ofs <= len;
		If Not (-1 <= lastOfs And lastOfs < ofs And ofs <= len) Then Error("gallopRight: honk honk")
		#End

'        /*
'         * Now a[b + lastOfs] <= key < a[b + ofs], so key belongs somewhere to
'         * the right of lastOfs but no farther right than ofs.  Do a binary
'         * search, with invariant a[b + lastOfs - 1] <= key < a[b + ofs].
'         */
        lastOfs += 1
        While (lastOfs < ofs)
            Local m:Int = lastOfs + ( (ofs - lastOfs) Shr 1)  'Should be unsigned shift  -nobu

            If (c.Compare(key, a[base + m]) < 0)
                ofs = m          ' key < a[b + m]
            else
                lastOfs = m + 1  ' a[b + m] <= key
			End If
        Wend
		
		#If CONFIG="debug"
        'assert lastOfs == ofs;    ' so a[b + ofs - 1] <= key < a[b + ofs]
		If lastOfs <> ofs Then Error("gallopRight: lastOfs <> ofs")
		#End


        Return ofs
    End Function

'    /**
'     * Merges two adjacent runs in place, in a stable fashion.  The first
'     * element of the first run must be greater than the first element of the
'     * second run (a[base1] > a[base2]), and the last element of the first run
'     * (a[base1 + len1-1]) must be greater than all elements of the second run.
'     *
'     * For performance, this method should be called only when len1 <= len2;
'     * its twin, mergeHi should be called if len1 >= len2.  (Either method
'     * may be called if len1 == len2.)
'     *
'     * @param base1 index of first element in first run to be merged
'     * @param len1  length of first run to be merged (must be > 0)
'     * @param base2 index of first element in second run to be merged
'     *        (must be aBase + aLen)
'     * @param len2  length of second run to be merged (must be > 0)
'     */
    Method mergeLo:Void(base1:Int, len1:Int, base2:Int, len2:Int)
		#If CONFIG="debug"
        'assert len1 > 0 && len2 > 0 && base1 + len1 == base2;
		If Not (len1 > 0 And len2 > 0 And base1 + len1 = base2) Then Error("mergeLo: honk")

		'Print("mergeLo: base1: " + base1 + ", len1: " + len1 + ", base2: " + base2 + ", len2: " + len2)
		#End
		
        ' Copy first run into temp array
        Local a:T[] = Self.a ' For performance
        Local tmp:T[] = ensureCapacity(len1)
        Arrays<T>.Copy(a, base1, tmp, 0, len1) 'System.arraycopy(a, base1, tmp, 0, len1);

        Local cursor1:Int = 0       ' Indexes into tmp array
        Local cursor2:Int = base2   ' Indexes int a
        Local dest:Int = base1      ' Indexes int a

        ' Move first element of second run and deal with degenerate cases
        'a[dest++] = a[cursor2++];
		a[dest] = a[cursor2]; dest += 1; cursor2 += 1
		
		'if (--len2 == 0) {
		len2 -= 1
        If (len2 = 0)
            Arrays<T>.Copy(tmp, cursor1, a, dest, len1) 'System.arraycopy(tmp, cursor1, a, dest, len1);
            Return
        End If
        If (len1 = 1)
            Arrays<T>.Copy(a, cursor2, a, dest, len2) 'System.arraycopy(a, cursor2, a, dest, len2);
            a[dest + len2] = tmp[cursor1] ' Last elt of run 1 to end of merge
            Return
        End If

        Local c:Comparator<T> = Self.c  ' Use local variable for performance
        Local minGallop:Int = Self.minGallop    '  "    "       "     "      "

    'outer:
	Local outerLoopBreak:Bool
        Repeat
            Local count1:Int = 0 ' Number of times in a row that first run won
            Local count2:Int = 0 ' Number of times in a row that second run won

'            /*
'             * Do the straightforward thing until (if ever) one run starts
'             * winning consistently.
'             */
            Repeat
                #If CONFIG="debug"
				'assert len1 > 1 && len2 > 0;
				If Not (len1 > 1 And len2 > 0) Then Error("mergeLo: len1 <= 1 or len2 <= 0")
				#End 
				
                If (c.Compare(a[cursor2], tmp[cursor1]) < 0) Then
                    'a[dest++] = a[cursor2++];
					a[dest] = a[cursor2]; dest += 1; cursor2 += 1
                    count2 += 1
                    count1 = 0
                    'if (--len2 == 0)
                        'break outer;
					len2 -= 1
					If len2 = 0 Then
						outerLoopBreak = True
						Exit
					End If
                Else
                    'a[dest++] = a[cursor1++];
                    a[dest] = tmp[cursor1]; dest += 1; cursor1 += 1
                    count1 += 1
                    count2 = 0
                    'if (--len1 == 1)
                        'break outer;
					len1 -= 1
					If len1 = 1 Then
						outerLoopBreak = True
						Exit
					End If
                End If
             Until Not ( (count1 | count2) < minGallop)

			 If outerLoopBreak = True Then Exit  'Break outer loop  -nobu
			 
'            /*
'             * One run is winning so consistently that galloping may be a
'             * huge win. So try that, and continue galloping until (if ever)
'             * neither run appears to be winning consistently anymore.
'             */
            Repeat
                #If CONFIG="debug"
				'assert len1 > 1 && len2 > 0;
				If Not (len1 > 1 And len2 > 0) Then Error("mergeLo: len1 <= 1 or len2 <= 0")
				#End 

                count1 = gallopRight(a[cursor2], tmp, cursor1, len1, 0, c)
                If (count1 <> 0) Then
                    Arrays<T>.Copy(tmp, cursor1, a, dest, count1) 'System.arraycopy(tmp, cursor1, a, dest, count1);
                    dest += count1
                    cursor1 += count1
                    len1 -= count1
                    If (len1 <= 1) Then ' len1 == 1 || len1 == 0
                        'break outer;
						outerLoopBreak = True
						Exit
					End If
                End If
                'a[dest++] = a[cursor2++];
				a[dest] = a[cursor2]; dest += 1; cursor2 += 1
				
                'if (--len2 == 0)
                    'break outer;
				len2 -= 1
				If len2 = 0 Then
					outerLoopBreak = True
					Exit
				End If
					
                count2 = gallopLeft(tmp[cursor1], a, cursor2, len2, 0, c)
                If (count2 <> 0)
                    Arrays<T>.Copy(a, cursor2, a, dest, count2) 'System.arraycopy(a, cursor2, a, dest, count2);
                    dest += count2
                    cursor2 += count2
                    len2 -= count2
                    'if (len2 == 0)
                        'break outer;
					If len2 = 0 Then
						outerLoopBreak = True
						Exit
					End If
                End If
                'a[dest++] = tmp[cursor1++];
                a[dest] = tmp[cursor1]; dest += 1; cursor1 += 1

                'If (--len1 == 1)
                    'break outer;
				len1 -= 1
				If len1 = 1 Then
					outerLoopBreak = True
					Exit
				End If

                minGallop -= 1
            Until Not (count1 >= MIN_GALLOP | count2 >= MIN_GALLOP)
			
			If outerLoopBreak = True Then Exit   'Break outer loop  -nobu
			
            If (minGallop < 0) Then minGallop = 0
            minGallop += 2  ' Penalize for leaving gallop mode
        Forever  ' End of "outer" loop
		
        'Self.minGallop = minGallop < 1 ? 1:minGallop;  ' Write back to field
		If minGallop < 1 Then Self.minGallop = 1 Else Self.minGallop = minGallop ' Write back to field

        If (len1 = 1)
            #If CONFIG="debug"
			  If len2 <= 0 Then Error("assert len2 > 0;")
			#End 
            Arrays<T>.Copy(a, cursor2, a, dest, len2) 'System.arraycopy(a, cursor2, a, dest, len2);
            a[dest + len2] = tmp[cursor1] '  Last elt of run 1 to end of merge
        ElseIf(len1 = 0)
			Print("len2: " + len2)
            'Error("mergeLo: Comparison method violates its general contract!")
        Else
 			#If CONFIG="debug"
              If len2 <> 0 Then Error("assert len2 == 0;")
              If len1 <= 1 Then Error("assert len1 > 1;")
			#End 
            Arrays<T>.Copy(tmp, cursor1, a, dest, len1) 'System.arraycopy(tmp, cursor1, a, dest, len1);
        End If
    End Method

'    /**
'     * Like mergeLo, except that this method should be called only if
'     * len1 >= len2; mergeLo should be called if len1 <= len2.  (Either method
'     * may be called if len1 == len2.)
'     *
'     * @param base1 index of first element in first run to be merged
'     * @param len1  length of first run to be merged (must be > 0)
'     * @param base2 index of first element in second run to be merged
'     *        (must be aBase + aLen)
'     * @param len2  length of second run to be merged (must be > 0)
'     */
    Method mergeHi:Void(base1:Int, len1:Int, base2:Int, len2:Int)
		#If CONFIG="debug"
        'assert len1 > 0 && len2 > 0 && base1 + len1 == base2;
		If Not (len1 > 0 And len2 > 0 And base1 + len1 = base2) Then Error("mergeHi: honk")
		
		'Print("MergeHi: base1: " + base1 + ", len1: " + len1 + ", base2: " + base2 + ", len2: " + len2)
		#End

		
        ' Copy second run into temp array
        Local a:T[] = Self.a ' For performance
        Local tmp:T[] = ensureCapacity(len2)
        Arrays<T>.Copy(a, base2, tmp, 0, len2) 'System.arraycopy(a, base2, tmp, 0, len2);

        Local cursor1:Int = base1 + len1 - 1  ' Indexes into a
        Local cursor2:Int = len2 - 1          ' Indexes into tmp array
        Local dest:Int = base2 + len2 - 1     ' Indexes into a

        ' Move last element of first run and deal with degenerate cases
        'a[dest--] = a[cursor1--];
        a[dest] = a[cursor1]; dest -= 1; cursor1 -= 1
		len1 -= 1
        If (len1 = 0) Then
            Arrays<T>.Copy(tmp, 0, a, dest - (len2 - 1), len2) 'System.arraycopy(tmp, 0, a, dest - (len2 - 1), len2)
            Return
        End If
        If (len2 = 1) Then
            dest -= len1
            cursor1 -= len1
            Arrays<T>.Copy(a, cursor1 + 1, a, dest + 1, len1) 'System.arraycopy(a, cursor1 + 1, a, dest + 1, len1);
            a[dest] = tmp[cursor2]
            Return
        End If

        Local c:Comparator<T> = Self.c   ' Use local variable for performance
        Local minGallop:Int = Self.minGallop    '  "    "       "     "      "
    'outer:
	Local outerLoopBreak:Bool
	
        Repeat
            Local count1:Int = 0 ' Number of times in a row that first run won
            Local count2:Int = 0 ' Number of times in a row that second run won

'            /*
'             * Do the straightforward thing until (if ever) one run
'             * appears to win consistently.
'             */
            Repeat
				#If CONFIG="debug" 
                'assert len1 > 0 && len2 > 1;
				If Not (len1 > 0 And len2 > 1) Then Error("mergeHi: len1 <=0 or len2 <=1")
				#End
				
                If (c.Compare(tmp[cursor2], a[cursor1]) < 0)
                    'a[dest--] = a[cursor1--];
					a[dest] = a[cursor1]; dest -= 1; cursor1 -= 1
                    count1 += 1
                    count2 = 0
                    'if (--len1 == 0)
                        'break outer;
					len1 -= 1
					If len1 = 0 Then
						outerLoopBreak = True
						Exit
					End If
                Else
                    'a[dest--] = tmp[cursor2--];
					a[dest] = tmp[cursor2]; dest -= 1; cursor2 -= 1
                    count2 += 1
                    count1 = 0
                    'if (--len2 == 1)
                        'break outer;
					len2 -= 1
					If len2 = 1 Then
						outerLoopBreak = True
						Exit
					End If
                End If
            Until Not ( (count1 | count2) < minGallop)

			If outerLoopBreak = True Then Exit  'Break outer loop  -nobu
			
'            /*
'             * One run is winning so consistently that galloping may be a
'             * huge win. So try that, and continue galloping until (if ever)
'             * neither run appears to be winning consistently anymore.
'             */
            Repeat
                #If CONFIG="debug"
				  'assert len1 > 0 && len2 > 1;
				  If Not (len1 > 0 And len2 > 1) Then Error("mergeHi: len1 <=0 or len2 <=1")
				#End If 
				
                count1 = len1 - gallopRight(tmp[cursor2], a, base1, len1, len1 - 1, c)
                If (count1 <> 0)
                    dest -= count1
                    cursor1 -= count1
                    len1 -= count1
					'System.arraycopy(a, cursor1 + 1, a, dest + 1, count1);
                    Arrays<T>.Copy(a, cursor1 + 1, a, dest + 1, count1)
                    'if (len1 == 0)
                        'break outer;
					If len1 = 0 Then
						outerLoopBreak = True
						Exit
					End If
                End If
                'a[dest--] = tmp[cursor2--];
				a[dest] = tmp[cursor2]; dest -= 1; cursor2 -= 1
                'if (--len2 == 1)
                    'break outer;
				len2 -= 1
				If len2 = 1 Then
					outerLoopBreak = True
					Exit
				End If

                count2 = len2 - gallopLeft(a[cursor1], tmp, 0, len2, len2 - 1, c)
                If (count2 <> 0)
                    dest -= count2
                    cursor2 -= count2
                    len2 -= count2
                    'System.arraycopy(tmp, cursor2 + 1, a, dest + 1, count2);
					Arrays<T>.Copy(tmp, cursor2 + 1, a, dest + 1, count2)
                    'If (len2 <= 1)  ' len2 == 1 || len2 == 0
                        'break outer;
					If len2 <= 1
						outerLoopBreak = True
						Exit
					End If
                End If
                'a[dest--] = a[cursor1--];
				a[dest] = a[cursor1]; dest -= 1; cursor1 -= 1
                'If (--len1 == 0)
                    'break outer;
				len1 -= 1
				If len1 = 0 Then
					outerLoopBreak = True
					Exit
				End If
					
                minGallop -= 1
            Until Not (count1 >= MIN_GALLOP | count2 >= MIN_GALLOP)
			
			If outerLoopBreak = True Then Exit 'Break outer loop  -nobu
			
            If (minGallop < 0) Then minGallop = 0
            minGallop += 2  ' Penalize for leaving gallop mode
        Forever  ' End of "outer" loop
		
        'Self.minGallop = minGallop < 1 ? 1:minGallop;  ' Write back to field
		If minGallop < 1 Then Self.minGallop = 1 Else Self.minGallop = minGallop ' Write back to field

        If (len2 = 1) Then
			#If CONFIG="debug"
              If len1 <= 0 Then Error("mergeHi: assert len1 > 0;")
			#End 
			
            dest -= len1
            cursor1 -= len1
            Arrays<T>.Copy(a, cursor1 + 1, a, dest + 1, len1) 'System.arraycopy(a, cursor1 + 1, a, dest + 1, len1);
            a[dest] = tmp[cursor2]  ' Move first elt of run2 to front of merge
        ElseIf(len2 = 0)
            'Error("mergeHi: Comparison method violates its general contract!")
        Else
			#If CONFIG="debug"
              If len1 <> 0 Then Error("mergeHi: assert len1 == 0;")
              If len2 <= 0 Then Error("mergeHi: assert len2 > 0;")
			#End 
            
            Arrays<T>.Copy(tmp, 0, a, dest - (len2 - 1), len2) 'System.arraycopy(tmp, 0, a, dest - (len2 - 1), len2);
        End If
    End Method

'    /**
'     * Ensures that the external array tmp has at least the specified
'     * number of elements, increasing its size if necessary.  The size
'     * increases exponentially to ensure amortized linear time complexity.
'     *
'     * @param minCapacity the minimum required capacity of the tmp array
'     * @return tmp, whether or not it grew
'     */
    Method ensureCapacity:T[] (minCapacity:Int)
        If (tmp.Length < minCapacity)
            ' Compute smallest power of 2 > minCapacity
            Local newSize:Int = minCapacity
            newSize |= newSize Shr 1
            newSize |= newSize Shr 2
            newSize |= newSize Shr 4
            newSize |= newSize Shr 8
            newSize |= newSize Shr 16
            newSize += 1

            If (newSize < 0) ' Not bloody likely!
                newSize = minCapacity
            Else
                newSize = Min(newSize, a.Length Shr 1)  'Unsigned shift should really be used here  -nobu
			End If
				
            'T[] newArray = (T[]) new Object[newSize];
			'Local newArray:T[]; newArray = newArray.Resize(newSize)
			Local newArray:T[newSize]
            tmp = newArray
        End If

        Return tmp
    End Method

'    /**
'     * Checks that fromIndex and toIndex are in range, and throws an
'     * appropriate exception if they aren't.
'     *
'     * @param arrayLen the length of the array
'     * @param fromIndex the index of the first element of the range
'     * @param toIndex the index after the last element of the range
'     * @throws IllegalArgumentException if fromIndex > toIndex
'     * @throws ArrayIndexOutOfBoundsException if fromIndex < 0
'     *         or toIndex > arrayLen
'     */
     Function rangeCheck:Void(arrayLen:Int, fromIndex:Int, toIndex:Int)
        if (fromIndex > toIndex)
            Error("fromIndex(" + fromIndex + ") > toIndex(" + toIndex + ")")
		End If
        if (fromIndex < 0)
            Error("Out of bounds: fromIndex " + fromIndex + "< 0")
		End If
        if (toIndex > arrayLen)
            Error("Out of bounds: toIndex " + toIndex + "> " + arrayLen)
		End If
    End Function
End Class
