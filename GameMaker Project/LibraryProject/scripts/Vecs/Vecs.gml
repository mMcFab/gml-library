// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Vecs() {};

function Vec2(_x = 0, _y = 0) constructor {
	x = _x;
	y = _y;
	
	static Normalize = function() {
		if(x == 0 && y == 0) {
			x = 1;
		};
		
		var _mag = sqrt(x * x + y * y);
		
		x /= _mag;
		y /= _mag;
	};
	
	static Copy = function() {
		return new Vec2(x);
	};
	
	//static Slerp = function(_target) {}; // NYI
}

function Vec3(_x = 0, _y = 0, _z = 0) : Vec2(_x, _y) constructor {
	
	z = _z;
	
	static Normalize = function() {
		if(x == 0 && y == 0 && z == 0) {
			x = 1;
		};
		
		var _mag = sqrt( x * x + y * y + z * z );
		
		x /= _mag;
		y /= _mag;
		z /= _mag;
		
		return self;
	};
	
	static Normalized = function() {
		return Copy().Normalize();
	};
	
	// static Equals = function()
	
	static Magnitude = function() {
		gml_pragma("forceinline");
		return sqrt( x * x + y * y + z * z );
	}
	
	static Copy = function() {
		gml_pragma("forceinline");
		return new Vec3(x, y, z);
	};
	
	static Dot = function(_vec3d) {
		gml_pragma("forceinline");
		return dot_product_3d(x, y, z, _vec3d.x, _vec3d.y, _vec3d.z);
	}
	
	static Cross = function(_vec3d, _result=(new Vec3())) {
		// I think I use the old math/geometric method of doing this in my 3D angine thing. This should be way more optimal as the math is tiny by comparison
		_result.x = (y * _vec3d.z) - (z * _vec3d.y);
		_result.y = (z * _vec3d.x) - (x * _vec3d.z);
		_result.z = (x * _vec3d.y) - (y * _vec3d.x);
		
		return _result;
		
	};
	
	//static Slerp = function(_target) {}; // NYI
};

function Vec4(_x = 0, _y = 0, _z = 0, _w = 0) : Vec3(_x, _y, _z) constructor {
	w = _w;
	
	static Normalize = function() {
		if(x == 0 && y == 0 && z == 0 && w == 0) {
			x = 1;
		};
		
		var _mag = sqrt( x * x + y * y + z * z + w * w);
		
		x /= _mag;
		y /= _mag;
		z /= _mag;
		w /= _mag;
	};
	
	static Copy = function() {
		return new Vec4(x, y, z, w);
	};
	
	//static Slerp = function(_target) {}; // NYI
}