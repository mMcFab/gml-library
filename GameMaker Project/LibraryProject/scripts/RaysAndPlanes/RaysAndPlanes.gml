// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function RaysAndPlanes(){}


function Ray3D(_pos=new Vec3(0, 0, 0), _direction=new Vec3(1,0,0)) constructor {
	
	position = _pos.Copy();
	direction = _direction.Copy();
	
	static Cast = function(_vec3_point, _vec3_normal) {
		
		if(is_undefined(_vec3_normal)) {
			return CastPlane(_vec3_point);
		}
		
		_vec3_normal = _vec3_normal.Normalized();
		var _c = -_vec3_normal.Dot(_vec3_point);
		
		var _denominator = _vec3_normal.Dot(direction);
		if(_denominator == 0) {
			return infinity;
		}
		var _numerator = _vec3_normal.Dot(position) + _c;
		var _t = -(_numerator / _denominator);
		
		//var _hit = new Vec3(position.x + direction.x * _t, 
		//					position.y + direction.y * _t,
		//					position.z + direction.z * _t);
		return _t;
	};
	
	static CastPlane = function(_plane3d) {
		var _denominator = _plane3d.normal.Dot(direction);
		if(_denominator == 0) {
			return infinity;
		}
		var _numerator = _plane3d.normal.Dot(position) + _plane3d.D;
		var _t = -(_numerator / _denominator);
		
		//var _hit = new Vec3(position.x + direction.x * _t, 
		//					position.y + direction.y * _t,
		//					position.z + direction.z * _t);
		return _t;
	};
}

function Plane3D(_point=new Vec3(0,0,0), _vec3_normal=new Vec3(0,0,1)) constructor {
	normal = _vec3_normal.Normalized();
	//offset = _offset;
	point = _point.Copy();
	D = -normal.Dot(point);
	
	static SetNormal = function(_vec3_normal) {
		normal.x = _vec3_normal.x;
		normal.y = _vec3_normal.y;
		normal.z = _vec3_normal.z;
		normal.Normalize();
		
		D = -normal.Dot(point);
	};
	
	static SetPoint = function(_point) {
		point.x = _point.x;
		point.y = _point.y;
		point.z = _point.z;
		D = -normal.Dot(point);
	};
	
	static SetPointCoords = function(_x, _y, _z) {
		point.x = _x;
		point.y = _y;
		point.z = _z;
		D = -normal.Dot(point);
	};
};
