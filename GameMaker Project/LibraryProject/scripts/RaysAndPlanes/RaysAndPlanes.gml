// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function RaysAndPlanes(){}


function Ray3D(_pos=new Vec3(0, 0, 0), _direction=new Vec3(1,0,0)) constructor {
	
	position = _pos.Copy();
	direction = _direction.Copy();
	
	//static Cast = function(_vec3_point, _vec3_normal) {
		
	//	if(is_undefined(_vec3_normal)) {
	//		return CastPlane(_vec3_point);
	//	}
		
	//	_vec3_normal = _vec3_normal.Normalized();
	//	var _c = -_vec3_normal.Dot(_vec3_point);
		
	//	var _denominator = _vec3_normal.Dot(direction);
	//	if(_denominator == 0) {
	//		return infinity;
	//	}
	//	var _numerator = _vec3_normal.Dot(position) + _c;
	//	var _t = -(_numerator / _denominator);
		
	//	//var _hit = new Vec3(position.x + direction.x * _t, 
	//	//					position.y + direction.y * _t,
	//	//					position.z + direction.z * _t);
	//	return _t;
	//};
	
	//static CastPlane = function(_plane3d) {
	//	var _denominator = _plane3d.normal.Dot(direction);
	//	if(_denominator == 0) {
	//		return infinity;
	//	}
	//	var _numerator = _plane3d.normal.Dot(position) + _plane3d.D;
	//	var _t = -(_numerator / _denominator);
		
	//	//var _hit = new Vec3(position.x + direction.x * _t, 
	//	//					position.y + direction.y * _t,
	//	//					position.z + direction.z * _t);
	//	return _t;
	//};
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
	
	static IntersectRay = function(_ray3d) {
		var _denominator = normal.Dot(_ray3d.direction);
		if(_denominator == 0) {
			return infinity;
		}
		var _numerator = normal.Dot(_ray3d.position) + D;
		var _t = -(_numerator / _denominator);
		
		//var _hit = new Vec3(position.x + direction.x * _t, 
		//					position.y + direction.y * _t,
		//					position.z + direction.z * _t);
		return _t;
	};
};

function Triangle3D(p1, p2, p3) constructor {
	
	#macro TRIANGLE3D_RAYCAST_BALDWIN_WEBER true
	
	pointA = p1.Copy();
	pointB = p2.Copy();
	pointC = p3.Copy();
	
	// By caching the edges, we can speed up relative intersection checks. 
	edgeAB = new Vec3(pointB.x - pointA.x, pointB.y - pointA.y, pointB.z - pointA.z);	
	edgeAC = new Vec3(pointC.x - pointA.x, pointC.y - pointA.y, pointC.z - pointA.z);
	
	normal = new Vec3();
	edgeAC.Cross(edgeAB, normal);
	normal.Normalize();
	
	
	
	// Möller–Trumbore intersection algorithm from https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
	// Adapated to use GML and vec3 things. Epsilon may not be necessary because of GMs built in epsilon, but this makes it follow rules more consistently (especially between C++ and GML)
	static IntersectMT = function(_ray3D, _outVector) {
		
		var EPSILON = 0.0000001;
	    
		// This should prevent any future memory allocations
		static h = new Vec3(), s = new Vec3(), q = new Vec3();
	    var a,f,u,v;
	    
	    _ray3D.direction.Cross(edgeAC, h);
	    a = edgeAB.Dot(h);
	    if (a > -EPSILON && a < EPSILON)
	        return false;    // This ray is parallel to this triangle.
	    f = 1.0/a;
		s.x = _ray3D.position.x - pointA.x;		
		s.y = _ray3D.position.y - pointA.y;
		s.z = _ray3D.position.z - pointA.z;

	    u = f * s.Dot(h);
	    if (u < 0.0 || u > 1.0)
	        return false;
	    s.Cross(edgeAB, q);
	    v = f * _ray3D.direction.Dot(q);
	    if (v < 0.0 || u + v > 1.0)
	        return false;
	    // At this stage we can compute t to find out where the intersection point is on the line.
	    var t = f * edgeAC.Dot(q);
	    if (t > EPSILON) // ray intersection
	    {
			_outVector.x = _ray3D.position.x + _ray3D.direction.x * t;
			_outVector.y = _ray3D.position.y + _ray3D.direction.y * t;
			_outVector.z = _ray3D.position.z + _ray3D.direction.z * t;

	        return true;
	    }
		
	    // This means that there is a line intersection but not a ray intersection.
		return false;
	}
	
	// Considering implementing the Baldwin-Weber algo https://jcgt.org/published/0005/03/03/
	// Since it can take less than half the time of the MT algo. 
	if(TRIANGLE3D_RAYCAST_BALDWIN_WEBER) {
		transformation = array_create(12);
		// Build transformation from global to barycentric coordinates.
    
	    var x1, x2;
	    var num = pointA.Dot( normal );                 // Element (3,4) of each transformation matrix
		
	    if (  abs( normal.x ) > abs( normal.y )  &&  abs( normal.x ) > abs( normal.z )  ) {
        
	        x1 = pointB.y * pointA.z - pointB.z * pointA.y;
	        x2 = pointC.y * pointA.z - pointC.z * pointA.y;
        
	        //Do matrix set up here for when a = 1, b = c = 0 formula

	        transformation[0] = 0.0;
	        transformation[1] = edgeAC.z / normal.x;
	        transformation[2] = -edgeAC.y / normal.x;
	        transformation[3] = x2 / normal.x;
        
	        transformation[4] = 0.0;
	        transformation[5] = -edgeAB.z / normal.x;
	        transformation[6] = edgeAB.y / normal.x;
	        transformation[7] = -x1 / normal.x;
        
	        transformation[8] = 1.0;
	        transformation[9] = normal.y / normal.x;
	        transformation[10] = normal.z / normal.x;
	        transformation[11] = -num / normal.x;
	    }
	    else if (  abs( normal.y ) > abs( normal.z )  ) {
        
	        x1 = pointB.z * pointA.x - pointB.x * pointA.z;
	        x2 = pointC.z * pointA.x - pointC.x * pointA.z;
        
	        // b = 1 case

	        transformation[0] = -edgeAC.z / normal.y;
	        transformation[1] = 0.0;
	        transformation[2] = edgeAC.x / normal.y;
	        transformation[3] = x2 / normal.y;
        
	        transformation[4] = edgeAB.z / normal.y;
	        transformation[5] = 0.0;
	        transformation[6] = -edgeAB.x / normal.y;
	        transformation[7] = -x1 / normal.y;
        
	        transformation[8] = normal.x / normal.y;
	        transformation[9] = 1.0;
	        transformation[10] = normal.z / normal.y;
	        transformation[11] = -num / normal.y;
	    }
	    else if ( abs( normal.z ) > 0.0 ) {
        
	        x1 = pointB.x * pointA.y - pointB.y * pointA.x;
	        x2 = pointC.x * pointA.y - pointC.y * pointA.x;
        
	        // c = 1 case

	        transformation[0] = edgeAC.y / normal.z;
	        transformation[1] = -edgeAC.x / normal.z;
	        transformation[2] = 0.0;
	        transformation[3] = x2 / normal.z;
        
	        transformation[4] = -edgeAB.y / normal.z;
	        transformation[5] = edgeAB.x / normal.z;
	        transformation[6] = 0.0;
	        transformation[7] = -x1 / normal.z;
        
	        transformation[8] = normal.x / normal.z;
	        transformation[9] = normal.y / normal.z;
	        transformation[10] = 1.0;
	        transformation[11] = -num / normal.z;
	    }
	    else {
	        throw( "Error: Building precomputed-transformation triangle from degenerate source" );
	    }
		
		
		static IntersectBW = function(_ray3D, _outVector) {
			// Get barycentric z components of ray origin and direction for calculation of t value
    
		    var transS = transformation[8] * _ray3D.position.x + transformation[9] * _ray3D.position.y + transformation[10] * _ray3D.position.z + transformation[11];
		    var transD = transformation[8] * _ray3D.direction.x + transformation[9] * _ray3D.direction.y + transformation[10] * _ray3D.direction.z;
    
		    var ta = -transS / transD;
    
    
		    // Reject negative t values and rays parallel to triangle
			//#define tFar   10000.0f
			//#define tNear  0.0000001f
		   // if ( ta <= tNear || ta >= tFar )		    
			if ( ta <= 0.0000001 || ta >= 10000.0 )
		        return false;
    
    
		    // Get global coordinates of ray's intersection with triangle's plane.
			// static wr = array_create(3);
		    _outVector.x = _ray3D.position.x + ta * _ray3D.position.z;
			_outVector.y = _ray3D.position.y + ta * _ray3D.position.y;
		    _outVector.z = _ray3D.position.z + ta * _ray3D.position.z;
			
		    // Calculate "x" and "y" barycentric coordinates
    
		    var xg = transformation[0] * _outVector.x + transformation[1] * _outVector.y + transformation[2] * _outVector.z + transformation[3];
		    var yg = transformation[4] * _outVector.x + transformation[5] * _outVector.y + transformation[6] * _outVector.z + transformation[7];
    
    
		    // final intersection test
    
		    if (  xg >= 0.0  &&  yg >= 0.0  &&  yg + xg < 1.0  )
		        return true;
    
		    return false;
		
		}
		
		
		static Intersect = IntersectBW;
		
	} else {
		static Intersect = IntersectMT;
	}
	
	// Consider Benthin+Walk, watertight ray/triangle intersection by woop. 
	
	// Badouel?? https://graphics.stanford.edu/courses/cs348b-98/gg/intersect.html
	
	
	
	
	
}
