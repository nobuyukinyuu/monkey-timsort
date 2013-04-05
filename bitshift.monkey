Import "native/bitshift.${TARGET}.${LANG}"

Extern

#If LANG<>"cpp"
	Function Lsr:Int( number:Int, shiftBy:Int ) = "Bitshift.Lsr"
	Function Lsl:Int( number:Int, shiftBy:Int ) = "Bitshift.Lsl"
#Else
	Function Lsr:Int( number:Int, shiftBy:Int ) = "Bitshift::Lsr"
	Function Lsl:Int( number:Int, shiftBy:Int ) = "Bitshift::Lsl"
#End