typedef unsigned int uint;

class Bitshift
{
	public:
	
	static int Lsr( int number, int shiftBy )
	{
		return (int)((uint)number >> shiftBy);
	}
	
	static int Lsl( int number, int shiftBy )
	{
		return (int)((uint)number << shiftBy);
	}
};