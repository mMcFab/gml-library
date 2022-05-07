// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Matrix() {};



//Default matrix transform always assumes w is 1 (not good for normals) and doesn't return a w component (not good for if you need a perspective divide)
function matrix_transform_vertex4(_matrix, _x, _y, _z, _w=1) {
	return [
		_matrix[0] * _x + _matrix[4] * _y + _matrix[8]  * _z + _matrix[12] * _w,
		_matrix[1] * _x + _matrix[5] * _y + _matrix[9]  * _z + _matrix[13] * _w,
		_matrix[2] * _x + _matrix[6] * _y + _matrix[10] * _z + _matrix[14] * _w, 
		_matrix[3] * _x + _matrix[7] * _y + _matrix[11] * _z + _matrix[15] * _w
	];
}

function matrix_invert(_matrix) {
	//Probably not a practical way to do this by reference. 
	//Kinda slow, don't do it a lot (partially why I don't build inverse-transposes for normals)
	//Luckily is fine a few times a frame, which can be handy for screen->world raycasting
	var _inv = array_create(16);//matrix_build_identity();
	_inv[0] =	_matrix[5]	*_matrix[10]	*_matrix[15]	-_matrix[5]*_matrix[11]*_matrix[14]-_matrix[9]*_matrix[6]*_matrix[15]+
		        _matrix[9]	*_matrix[7]		*_matrix[14]	+_matrix[13]*_matrix[6]*_matrix[11]-_matrix[13]*_matrix[7]*_matrix[10];
	_inv[4] = -	_matrix[4]	*_matrix[10]	*_matrix[15]	+_matrix[4]*_matrix[11]*_matrix[14]+_matrix[8]*_matrix[6]*_matrix[15]-
		        _matrix[8]	*_matrix[7]		*_matrix[14]	-_matrix[12]*_matrix[6]*_matrix[11]+_matrix[12]*_matrix[7]*_matrix[10];
	_inv[8] =	_matrix[4]	*_matrix[9]		*_matrix[15]	-_matrix[4]*_matrix[11]*_matrix[13]-_matrix[8]*_matrix[5]*_matrix[15]+
		        _matrix[8]	*_matrix[7]		*_matrix[13]	+_matrix[12]*_matrix[5]*_matrix[11]-_matrix[12]*_matrix[7]*_matrix[9];
	_inv[12]= -	_matrix[4]	*_matrix[9]		*_matrix[14]	+_matrix[4]*_matrix[10]*_matrix[13]+_matrix[8]*_matrix[5]*_matrix[14]-
		        _matrix[8]	*_matrix[6]		*_matrix[13]	-_matrix[12]*_matrix[5]*_matrix[10]+_matrix[12]*_matrix[6]*_matrix[9];
	_inv[1] = -	_matrix[1]	*_matrix[10]	*_matrix[15]	+_matrix[1]*_matrix[11]*_matrix[14]+_matrix[9]*_matrix[2]*_matrix[15]-
		        _matrix[9]	*_matrix[3]		*_matrix[14]	-_matrix[13]*_matrix[2]*_matrix[11]+_matrix[13]*_matrix[3]*_matrix[10];
	_inv[5] =	_matrix[0]	*_matrix[10]	*_matrix[15]	-_matrix[0]*_matrix[11]*_matrix[14]-_matrix[8]*_matrix[2]*_matrix[15]+
		        _matrix[8]	*_matrix[3]		*_matrix[14]	+_matrix[12]*_matrix[2]*_matrix[11]-_matrix[12]*_matrix[3]*_matrix[10];
	_inv[9] = -	_matrix[0]	*_matrix[9]		*_matrix[15]	+_matrix[0]*_matrix[11]*_matrix[13]+_matrix[8]*_matrix[1]*_matrix[15]-
		        _matrix[8]	*_matrix[3]		*_matrix[13]	-_matrix[12]*_matrix[1]*_matrix[11]+_matrix[12]*_matrix[3]*_matrix[9];
	_inv[13]=	_matrix[0]	*_matrix[9]		*_matrix[14]	-_matrix[0]*_matrix[10]*_matrix[13]-_matrix[8]*_matrix[1]*_matrix[14]+
		        _matrix[8]	*_matrix[2]		*_matrix[13]	+_matrix[12]*_matrix[1]*_matrix[10]-_matrix[12]*_matrix[2]*_matrix[9];
	_inv[2] =	_matrix[1]	*_matrix[6]		*_matrix[15]	-_matrix[1]*_matrix[7]*_matrix[14]-_matrix[5]*_matrix[2]*_matrix[15]+
		        _matrix[5]	*_matrix[3]		*_matrix[14]	+_matrix[13]*_matrix[2]*_matrix[7]-_matrix[13]*_matrix[3]*_matrix[6];
	_inv[6] = -	_matrix[0]	*_matrix[6]		*_matrix[15]	+_matrix[0]*_matrix[7]*_matrix[14]+_matrix[4]*_matrix[2]*_matrix[15]-
		        _matrix[4]	*_matrix[3]		*_matrix[14]	-_matrix[12]*_matrix[2]*_matrix[7]+_matrix[12]*_matrix[3]*_matrix[6];
	_inv[10]=	_matrix[0]	*_matrix[5]		*_matrix[15]	-_matrix[0]*_matrix[7]*_matrix[13]-_matrix[4]*_matrix[1]*_matrix[15]+
		        _matrix[4]	*_matrix[3]		*_matrix[13]	+_matrix[12]*_matrix[1]*_matrix[7]-_matrix[12]*_matrix[3]*_matrix[5];
	_inv[14]= -	_matrix[0]	*_matrix[5]		*_matrix[14]	+_matrix[0]*_matrix[6]*_matrix[13]+_matrix[4]*_matrix[1]*_matrix[14]-
		        _matrix[4]	*_matrix[2]		*_matrix[13]	-_matrix[12]*_matrix[1]*_matrix[6]+_matrix[12]*_matrix[2]*_matrix[5];
	_inv[3] = -	_matrix[1]	*_matrix[6]		*_matrix[11]	+_matrix[1]*_matrix[7]*_matrix[10]+_matrix[5]*_matrix[2]*_matrix[11]-
		        _matrix[5]	*_matrix[3]		*_matrix[10]	-_matrix[9]*_matrix[2]*_matrix[7]+_matrix[9]*_matrix[3]*_matrix[6];
	_inv[7] =	_matrix[0]	*_matrix[6]		*_matrix[11]	-_matrix[0]*_matrix[7]*_matrix[10]-_matrix[4]*_matrix[2]*_matrix[11]+
		        _matrix[4]	*_matrix[3]		*_matrix[10]	+_matrix[8]*_matrix[2]*_matrix[7]-_matrix[8]*_matrix[3]*_matrix[6];
	_inv[11]= -	_matrix[0]	*_matrix[5]		*_matrix[11]	+_matrix[0]*_matrix[7]*_matrix[9]+_matrix[4]*_matrix[1]*_matrix[11]-
		        _matrix[4]	*_matrix[3]		*_matrix[9]		-_matrix[8]*_matrix[1]*_matrix[7]+_matrix[8]*_matrix[3]*_matrix[5];
	_inv[15]=	_matrix[0]	*_matrix[5]		*_matrix[10]	-_matrix[0]*_matrix[6]*_matrix[9]-_matrix[4]*_matrix[1]*_matrix[10]+
		        _matrix[4]	*_matrix[2]		*_matrix[9]		+_matrix[8]*_matrix[1]*_matrix[6]-_matrix[8]*_matrix[2]*_matrix[5];

	var det = _matrix[0]*_inv[0]+_matrix[1]*_inv[4]+_matrix[2]*_inv[8]+_matrix[3]*_inv[12];
	if (det == 0) return _matrix;
	// var inverse;
	det = 1.0 / det;
	for (var i = 0; i < 16; i++) _inv[i] *= det;
	return _inv;
}
	
	
function matrix_transpose(_matrix, _byref=true) {
	
	if(!_byref)
	{
	    var _transposed = -1;
	    var _t = 0;
	    for (var _i = 0; _i < 4; ++_i) {
	      for (var _j = 0; _j < 4; ++_j) {
	        _transposed[_t++] = _matrix[_j * 4 + _i];
	      }
	    }
	    return _transposed;
	}
	else
	{
	    for (var _i = 0; _i < 4; ++_i) {
	      for (var _j = 0; _j < 4; ++_j) {
	        if((3 - _j) + _i > 3)
	        {
	            var _i1 = (_j * 4) + _i;
	            var _i2 = (_i * 4) + _j;
	            var _a1 = _matrix[_i1];
	            //var _a2 = _matrix[_i2];
	            _matrix[@ _i1] = _matrix[_i2];//_a2;
	            _matrix[@ _i2] = _a1;
            
	        }
	      }
	    }
	    return _matrix;
	}
}

