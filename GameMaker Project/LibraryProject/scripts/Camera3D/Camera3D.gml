// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

global.ACTIVE_CAMERA = undefined;

enum camera_projections {
	ortho, 
	perspective, 
	// perspective_fov, 
	NULL
}


function Camera3D(_projection_type = camera_projections.perspective, _znear = 32, _zfar = 32000, _fov_or_width = undefined, _aspect_or_height = undefined) constructor {
	cam = camera_create();
	
	var _fov;// = 60;
	var _width;// = window_get_width();
	var _height;// = window_get_height();
	var _aspect;// = 1;
	
	if(_projection_type = camera_projections.perspective) {
		if(is_undefined(_fov_or_width)) {
			_fov_or_width = 60;
		}
		var _application = application_get_position();
		
		if(is_undefined(_aspect_or_height)) {
			_aspect_or_height = (_application[2] - _application[0]) / (_application[3] - _application[1]);
		}
		
		_aspect = _aspect_or_height;
		_fov = _fov_or_width;
		
		_height = (_application[2] - _application[0]);
		_width = _height * _aspect;
	} else {
		var _application = application_get_position();
		if(is_undefined(_fov_or_width)) {
			_fov_or_width = (_application[2] - _application[0]);
		}
		if(is_undefined(_aspect_or_height)) {
			_aspect_or_height = (_application[3] - _application[1]);
		}
		
		_width = _fov_or_width;
		_height = _aspect_or_height;
		_fov = 0;
		_aspect = _width / _height;
	}
	
	
	update_function = undefined;
	update_function_parameters = undefined;
	
	bound_view = -1;
	
	static GetGameMakerCamera = function() {
		return cam;
	}
	
	static SetView = function(_view) {
		view_set_camera(_view, cam);
		bound_view = _view;
	}
	
	static CleanUp = function() {
		if(!is_undefined(cam)) {
			camera_destroy(cam);
			cam = undefined;
			if(bound_view > -1) {
				view_set_camera(bound_view, -1)
				bound_view = -1;
			}
		}
		
	}
	
	base_orientation_vectors = {
		forward : new Vec3(0, 1, 0),
		up : new Vec3(0, 0, -1),
		// right : new Vec3(1, 0, 0)// Right must be calculated to be perpendiclar to forward and up. It has No Base orientation
	}
	
	// lookat = new Vec3(0, 0, 0);
	var _pos_scale = 32;
	position = new Vec3(-base_orientation_vectors.forward.x * _pos_scale, -base_orientation_vectors.forward.y * _pos_scale, -base_orientation_vectors.forward.z * _pos_scale);
	
	
	forward = base_orientation_vectors.forward.Copy();
	up = base_orientation_vectors.up.Copy();
	right = up.Cross(forward);// CalcRight();// base_orientation_vectors.right.Copy();
	
	// lookat_mode = false;
	
	projection = {
		fov : _fov,
		znear : _znear,
		zfar : _zfar,
		size : new Vec2(_width, _height), 
		aspect : _width / _height, 
		type : _projection_type, 	
	};
	
	mat_proj = undefined;
	mat_view = undefined;
	mat_view_proj = undefined;
	
	p_update_proj = true;
	p_update_lookat = true;
	p_update_viewproj = true;
	
	cached_euler_orientation = new Vec3(undefined, 0, 0);
	
	// p_update_inverse = true;
	// inv_mat = array_create(16);
	
	
	
	static SetCameraUpdateMethod = function(_method, _parameters) {
		update_function = _method;
		update_function_parameters = _parameters;
		
		return self;
	};
	
	static GetCameraUpdateMethod = function() {
		return update_function;
	};
	
	static GetCameraUpdateParameters = function() {
		return update_function_parameters;
	}
	
	// Demo update scripts
	static CameraUpdateOrbital = function(_camera, _parameters) {
		
		if(is_undefined(_parameters)) {
			return { target : new Vec3(), distance : 64, yaw : 0, pitch : 0, roll : 0 };
		}
		
		
		_camera.Rotation(_parameters.pitch, _parameters.roll, _parameters.yaw);
		
		var _ox = lengthdir_y(_parameters.distance, _parameters.yaw) * dcos(_parameters.pitch);
		var _oy = lengthdir_x(-_parameters.distance, _parameters.yaw) * dcos(_parameters.pitch);
		var _oz = lengthdir_y(-_parameters.distance, _parameters.pitch);
		
		_camera.Position(_parameters.target.x + _ox, _parameters.target.y + _oy, _parameters.target.z + _oz);
		
		// So you can get the parameters? 
		return _parameters;
	}; 
	
	static CameraUpdateChase = function(_camera, _parameters) {
		if(is_undefined(_parameters)) {
			return { target : new Vec3(), distance : 64, height : -32, lerp_rate : 1 };
		}
		var _current_pos = _camera.GetPosition();
		
		var _direction = point_direction(_parameters.target.x, _parameters.target.y, _current_pos.x, _current_pos.y);
		var _distance = min(point_distance(_parameters.target.x, _parameters.target.y, _current_pos.x, _current_pos.y), _parameters.distance);
		
		_current_pos.x = lerp(_current_pos.x, _parameters.target.x + lengthdir_x(_distance, _direction), _parameters.lerp_rate);
		_current_pos.y = lerp(_current_pos.y, _parameters.target.y + lengthdir_y(_distance, _direction), _parameters.lerp_rate);
		_current_pos.z = lerp(_current_pos.z, _parameters.target.z + _parameters.height, _parameters.lerp_rate);
		
		
		
		
		_camera.Position(_current_pos.x, _current_pos.y, _current_pos.z);
		_camera.LookAt(_parameters.target.x, _parameters.target.y, _parameters.target.z);
		
		// So you can get the parameters? 
		return _parameters;
	};  
	
	
	static Clipping = function(_near, _far) {
		if(!is_undefined(_near))
			projection.znear = _near;
		
		if(!is_undefined(_far))
			projection.zfar = _far;
		
		p_update_proj = true;
		
		return self;
	};
	
	static Perspective = function(_fovy, _aspect, _near, _far) {
		
		projection.type = camera_projections.perspective;
		
		if(!is_undefined(_fovy))
			projection.fov = _fovy;
		if(!is_undefined(_aspect))
			projection.aspect = _aspect;
			
			
		
		if(!is_undefined(_near))
			projection.znear = _near;
		if(!is_undefined(_far))
			projection.zfar = _far;
		
		// projection.type = camera_projections.perspective_fov;
		/*// Commented out because it's expensive and near-useless. Saying that, if I did the math here and used matrix_build_perspective (no-fov) it would reduce dtan calls per frame.... hmmmm....
		// Yeah hypothetically this is cheaper overall, 1 fewer dtan per game call. 
		// Or is it? Not really, unless you only change aspect ratios (that'd be strangeish?) Since the matrix only gets rebuilt if this is called. 
		// Thinking about this more - that one necessary tan call internal to the function is better if Perspective gets called a lot for some reason without a rebuild, since it would result in tan operations with no purpose. 
		projection.size.y = 2 * projection.znear * dtan(projection.fov * 0.5);
		projection.size.x = _aspect * projection.size.y;
		// */
		// projection.znear = _znear;
		// projection.zfar = _zfar;
		
		p_update_proj = true;
		
		return self;
	};
	
	
	
	// Clipping required here because of Weird-Algo (the Math-based Polka musician)
	// But yeah, this is a sort-of replication of GM's internal code for this (but kinda backwards) so it functions the same weird way, without needing a specific handler. 
	static PerspectiveSize = function(_width = projection.size.x, _height = projection.size.y, _znear, _zfar) {
		// projection.fov = _fovy;
		projection.aspect = _width/_height;
		
		projection.size.x = _width;
		projection.size.y = _height;
		
		if(!is_undefined(_znear))
			projection.znear = _znear;
		if(!is_undefined(_zfar))
			projection.zfar = _zfar;
		
		projection.fov = (2.0 * darctan(1.0 / ((2.0 * _znear) / _height)));
		// show_debug_message(projection.fov);// 150
		
		projection.type = camera_projections.perspective;
		// projection.type = camera_projections.perspective_fov;
		
		p_update_proj = true;
		
		return self;
	};
	
	static Ortho = function(_width = projection.size.x, _height = projection.size.y) {
		projection.size.x = _width;
		projection.size.y = _height;
		
		projection.type = camera_projections.ortho;
		
		p_update_proj = true;
		
		return self;
	};
	
	
	
	
	// static Position = function(_x = position.x, _y = position.y, _z = position.z) {
	static Position = function(_x = 0, _y = 0, _z = 0) {
		position.x = _x;
		position.y = _y;
		position.z = _z;
		p_update_lookat = true;
		
		return self;
	};
	
	static GetPosition = function() {
		return position.Copy();
	}
	
	
	/* // Allows rotating of the preferred base up vector, since Y must always be 1 for base roations?
	static BaseUpOrientation = function(_angle) {
		base_orientation_vectors.up.x = lengthdir_x(1, _angle - 90);
		base_orientation_vectors.up.z = lengthdir_y(1, _angle - 90);
	}// */
	
	// static Up = function(_x = up.x, _y = up.y, _z = up.z) {
	static Up = function(_x, _y, _z ) {
	// static Up = function(_x = 0, _y = 0, _z = -1) {
		if(!is_undefined(_x))
			up.x = _x;
		if(!is_undefined(_y))
			up.y = _y;
		if(!is_undefined(_z))
			up.z = _z;
		
		up.Normalize();
		
		// PreferredUp(_x, _y, _z);
		
		forward.Cross(up, right);
		
		cached_euler_orientation.x = undefined;
		
		p_update_lookat = true;
		
		return self;
	};
	
	// Optional preferred up direction? 
	static Direction = function(_x, _y, _z) {
		// This doesn't really help with up vector rotation, huh. 
		
		forward.x = _x;
		forward.y = _y;
		forward.z = _z;
		
		forward.Normalize();
		
		
		// Only need to calculate up here and it's ready?? 
		// So if I cross true forward with base_up, I get true right. If I cross true right with forward, I get true up.
		// If abs(forward.Dot base_up) == 1, then we just cheat? Sub in a different vaalue. 
		var _dot = forward.Dot(base_orientation_vectors.up);
		if(abs(_dot) < 1) {
			forward.Cross(base_orientation_vectors.up, right);
			right.Normalize();
			
			forward.Cross(right, up);
			up.Normalize();
			
		} else {
			up.x = base_orientation_vectors.forward.x * sign(_dot);
			up.y = base_orientation_vectors.forward.y * sign(_dot);
			up.z = base_orientation_vectors.forward.z * sign(_dot);
			
			forward.Cross(up, right);
		}
		
		// up.Cross(forward, right);
		
		// We don't have to check for parallelism for right, since we define up as perpendicular to forward. 
		cached_euler_orientation.x = undefined;
		
		// lookat_mode = false;
		p_update_lookat = true;
		
		return self;
	};
	
	
	static LookAt = function(_x, _y, _z) {
		Direction(	_x - position.x,
					_y - position.y,
					_z - position.z);
		
		return self;
	};
	
	// Remember - Y-X-Z, 
	// This one is generally preferred over direction/lookat since you actually define what z-up is, thus allowing full rotations without messing up. 
	static Rotation = function(_pitch, _roll, _yaw) {
	// static Rotation = function(_pitch, _roll, _yaw) {
		// Allow passing a vec3
		if(is_struct(_pitch)) {
			_yaw = _pitch.z;
			_roll = _pitch.y;
			_pitch = _pitch.x;
		} 
		
		
		cached_euler_orientation.x = _pitch;
		cached_euler_orientation.y = _roll; 
		cached_euler_orientation.z = _yaw;
		
		var _mat = matrix_build(0, 0, 0, _pitch, _roll, _yaw, 1, 1, 1);
		
		var _dir = matrix_transform_vertex(_mat, base_orientation_vectors.forward.x, base_orientation_vectors.forward.y, base_orientation_vectors.forward.z);
		var _up = matrix_transform_vertex(_mat, base_orientation_vectors.up.x, base_orientation_vectors.up.y, base_orientation_vectors.up.z);
		
		// Can't just transform right since it doesn't have a base orientation - it is defined by forward and up, so we re-calc with cross. 
		// var _right = matrix_transform_vertex(_mat, base_orientation_vectors.right.x, base_orientation_vectors.right.y, base_orientation_vectors.right.z);
		
		
		
		
		// right.x = _right[0];
		// right.y = _right[1];
		// right.z = _right[2];
		
		forward.x = _dir[0];
		forward.y = _dir[1];
		forward.z = _dir[2];
		
		up.x = _up[0];
		up.y = _up[1];
		up.z = _up[2];
		
		forward.Cross(up, right);
		
		// lookat_mode = false;
		p_update_lookat = true;
		
		return self;
	};
	
	// Returns a Vec3 where _x = _pitch, y = _roll, z = _yaw
	// This will be the same as arguments passed in by Rotation(), but will otherwise calculate alternative "correct" values to get to the orientation - these values may not be what you expect. 
	static GetRotationEuler = function() {
		// Since we know up and forward, and their bases, we can get the rotation values, without too much trouble I think, if I remember right. 
		
		// So, yaw is normalised xy comparison of forward. If forward is 0, assume no yaw.
		
		// cached_euler_orientation.x = undefined;// Just used to force enable for testing
		
		// pitch is something...
		// Only do expensive re-calculate if it's actually changed. 
		if(is_undefined(cached_euler_orientation.x)) {
			var _yaw = 0;
			var _pitch = 0;
			var _roll = 0;
			
			var _xy_mag = sqrt(forward.x * forward.x + forward.y * forward.y);
			
			#region calc yaw
			if(_xy_mag != 0) {
				var _xx = forward.x / _xy_mag;
				var _yy = forward.y / _xy_mag;
				
				var dot = base_orientation_vectors.forward.x*_xx + base_orientation_vectors.forward.y*_yy;//      # dot product between [x1, y1] and [x2, y2]
				var det = base_orientation_vectors.forward.x*_yy - base_orientation_vectors.forward.y*_xx;//      # determinant
				_yaw = -darctan2(det, dot);//  # atan2(y, x) or atan2(sin, cos)
				
			}
			#endregion
			
			#region calc pitch
			
			var dot = base_orientation_vectors.forward.y*_xy_mag + base_orientation_vectors.forward.z*forward.z;//      # dot product between [x1, y1] and [x2, y2]
			var det = base_orientation_vectors.forward.y*forward.z - base_orientation_vectors.forward.z*_xy_mag;//      # determinant
			_pitch = -darctan2(det, dot);//  # atan2(y, x) or atan2(sin, cos)
			
			#endregion
			
			// Could simplify if we trusted some orientation values were zero, but whatevs. 
			// _pitch = point_direction(0, 0, _xy_mag, forward.z);
			
			#region calc roll - requires the other two to be done first
			// ok, since the up vector can end up in all places that roll can put it *without rolling*, I need to transform up be -yaw, then -pitch and then compare angles
			// base_orientation_vectors.
			// so what will change with roll rotating.... 
			// z remains constant when rotating the roll back by yaw. 
			
			var _xx = (up.y * dsin(-_yaw) + up.x * dcos(-_yaw));
			
			var _yy = (up.y * dcos(-_yaw) - up.x * dsin(-_yaw));
			// so x will now not change. 
			// So rotate new y and old z up?? 
			var _zz = up.z * dcos(-_pitch) - _yy * dsin(-_pitch);
			
			// _yy = up.z * dsin(-_pitch) + _yy * dcos(-_pitch);// Doesn't need to happen. It should always be 0 at this point. 
			var dot = base_orientation_vectors.up.z*_zz + base_orientation_vectors.up.x*_xx;//      # dot product between [x1, y1] and [x2, y2]
			var det = base_orientation_vectors.up.z*_xx - base_orientation_vectors.up.x*_zz;//      # determinant
			
			_roll = -darctan2(det, dot);//  # atan2(y, x) or atan2(sin, cos)
			
			// now it's just the angle difference between base_up and x/z. 
			#endregion
			
			cached_euler_orientation.x = _pitch;
			
			cached_euler_orientation.y = _roll;
			
			cached_euler_orientation.z = _yaw;
			
		}
		
		
		return cached_euler_orientation.Copy();
	};
	
	static GetForward = function() {
		return forward.Copy();
	};
	
	static GetUp = function() {
		return up.Copy();
	};
	
	static GetRight = function() {
		return right.Copy();
	};
	
	
	static GetMatProj = function(_copy_array=array_create(16)) {
		Recalculate();
		
		array_copy(_copy_array, 0, mat_proj, 0, 16);
		
		return _copy_array;
	};
	
	static GetMatView = function(_copy_array=array_create(16)) {
		Recalculate();
		
		array_copy(_copy_array, 0, mat_view, 0, 16);
		
		return _copy_array;
	};
	
	static GetMatViewProj = function(_copy_array=array_create(16)) {
		Recalculate();
		
		if(p_update_viewproj) {
			mat_view_proj = matrix_multiply(mat_view, mat_proj);
			p_update_viewproj = false;
		}
		
		array_copy(_copy_array, 0, mat_view_proj, 0, 16);
		
		return _copy_array;
	};
	
	
	static SetProjMat = function(_mat) {
		camera_set_proj_mat(cam, _mat);
		mat_proj = _mat;
		p_update_proj = false;
		p_update_viewproj = true;
	};
	
	static SetViewMat = function(_mat) {
		camera_set_view_mat(cam, _mat);
		mat_view = _mat;
		p_update_lookat = false;
		p_update_viewproj = true;
	};
	
	static Recalculate = function() {
		gml_pragma("forceinline");
		// var _update_viewproj = false;
		
		
		if(is_method(update_function)) {
			
			update_function(self, update_function_parameters);
		}
		
		if(p_update_proj) {
			switch(projection.type) {
				case camera_projections.perspective:// _fov:
					mat_proj = matrix_build_projection_perspective_fov(-projection.fov, projection.aspect, projection.znear, projection.zfar);
					// Technically saves a dtan2 if I use the lower one, unless PerspectiveFOV gets called a lot, in which case I'd do a lot of dtan2s
					// mat_proj = matrix_build_projection_perspective(projection.size.x, -projection.size.y, projection.znear, projection.zfar);
				break;
				// case camera_projections.perspective: // I reversed the code for non-fov so I can just use the one algo above now. 
				// 	mat_proj = matrix_build_projection_perspective(projection.size.x, -projection.size.y, projection.znear, projection.zfar);
				// break;
				case camera_projections.ortho: default:
					mat_proj = matrix_build_projection_ortho(projection.size.x, -projection.size.y, projection.znear, projection.zfar);
				break;
			}
			camera_set_proj_mat(cam, mat_proj);
			p_update_proj = false;
			p_update_viewproj = true;
		}
		
		
		
		if(p_update_lookat) {
				
			var _lookat_x = position.x + forward.x;
			var _lookat_y = position.y + forward.y;
			var _lookat_z = position.z + forward.z;
			
			mat_view = matrix_build_lookat(position.x, position.y, position.z, _lookat_x, _lookat_y, _lookat_z, up.x, up.y, up.z);
			camera_set_view_mat(cam, mat_view);
			p_update_lookat = false;
			p_update_viewproj = true;
		}
		// p_update_inverse = p_update_inverse || p_update_viewproj;
		
		return self;
	}
	
	static Apply = function() {
		Recalculate();
		
		global.ACTIVE_CAMERA = self;
		
		camera_apply(cam);
		
		return self;
	};
	
	camera_set_update_script(cam, method(self, Recalculate));
	
	
	static TransformToScreenSpace = function(_x = 0, _y = 0, _z = 0) {
		
		if(is_struct(_x)) {
			_z = _x.z;
			_y = _x.y;
			_x = _x.x;
		}
		
		//Recalculate();
		
		var _mat = GetMatViewProj();//mat_view_proj;//matrix_multiply((global.DOMINANT_CONTROLLER.camera.mat_look), (global.DOMINANT_CONTROLLER.camera.mat_proj));
		var _screen_pos = matrix_transform_vertex4(_mat, _x, _y, _z, 1);
		if(_screen_pos[3] != 0) {
			_screen_pos[0] /= _screen_pos[3];
			_screen_pos[1] /= _screen_pos[3];
			_screen_pos[2] /= _screen_pos[3];
		} 
		
		_screen_pos[0] = ((_screen_pos[0] + 1) / 2);
		_screen_pos[1] = ((_screen_pos[1] + 1) / 2);
		
		return _screen_pos;
	}
	
	//the idea is that we create a vector for the mouse. 
	//Then we simply calculate the intersection on a plane to determine the world position. 
	//This is much more accurate and flexible. 
	//x/y in range 0-1
	static ScreenSpaceToRay = function(_x, _y) {
		if(p_update_inverse) {
			inv_mat = matrix_invert(GetMatViewProj());
			p_update_inverse = false;
		}
		_x = (_x * 2) - 1;
		_y = (_y * 2) - 1;
		
		var _nearpoint = matrix_transform_vertex4(inv_mat, _x, _y, 0, 1);
		var _farpoint = matrix_transform_vertex4(inv_mat, _x, _y, 1, 1);
		//Always perspective divice? 
		if(_nearpoint[3] != 0) {
			_nearpoint[0] /= _nearpoint[3];
			_nearpoint[1] /= _nearpoint[3];
			_nearpoint[2] /= _nearpoint[3];
		}
		if(_farpoint[3] != 0) {
			_farpoint[0] /= _farpoint[3];
			_farpoint[1] /= _farpoint[3];
			_farpoint[2] /= _farpoint[3];
		}
		
		var _direction_x = _farpoint[0] - _nearpoint[0];
		var _direction_y = _farpoint[1] - _nearpoint[1];
		var _direction_z = _farpoint[2] - _nearpoint[2];
		var _mag = 1/sqrt(_direction_x * _direction_x + _direction_y * _direction_y + _direction_z * _direction_z);
		_direction_x *= _mag;
		_direction_y *= _mag;
		_direction_z *= _mag;
		
		return new Ray3D(
			new Vec3(_nearpoint[0], _nearpoint[1], _nearpoint[2]), 
			new Vec3(_direction_x, _direction_y, _direction_z)
		);
	}
}