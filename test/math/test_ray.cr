require "../minitest_helper"

class TestRay < Minitest::Test
  TOL = 0.0001

  def test_constructor_equals
    a = Tres::Ray.new
    assert_equal(zero3, a.origin)
    assert_equal(zero3, a.direction)

    a = Tres::Ray.new(two3.clone, one3.clone)
    assert_equal(two3, a.origin)
    assert_equal(one3, a.direction)
  end

  def test_copy_equals
    a = Tres::Ray.new(zero3.clone, one3.clone)
    b = Tres::Ray.new.copy(a)
    assert_equal(zero3, b.origin)
    assert_equal(one3, b.direction)

    # ensure that it is a true copy
    a.origin = zero3
    a.direction = one3
    assert_equal(zero3, b.origin)
    assert_equal(one3, b.direction)
  end

  def test_set
    a = Tres::Ray.new

    a.set(one3, one3)
    assert_equal(one3, a.origin)
    assert_equal(one3, a.direction)
  end

  def test_at
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    assert_equal(one3, a.at(0))
    assert_equal(Tres::Vector3.new(1, 1, 0), a.at(-1))
    assert_equal(Tres::Vector3.new(1, 1, 2), a.at(1))
  end

  def test_recast_clone
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    assert_equal(a, a.recast(0))

    b = a.clone
    assert_equal(Tres::Ray.new(Tres::Vector3.new(1, 1, 0), Tres::Vector3.new(0, 0, 1)), b.recast(-1))

    c = a.clone
    assert_equal(Tres::Ray.new(Tres::Vector3.new(1, 1, 2), Tres::Vector3.new(0, 0, 1)), c.recast(1))

    d = a.clone
    e = d.clone.recast(1)
    assert_equal(a, d)
    refute_equal(d, e)
    assert_equal(c, e)
  end

  def test_closest_point_to_point
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    # behind the ray
    b = a.closest_point_to_point(zero3)
    assert_equal(one3, b)

    # front of the ray
    c = a.closest_point_to_point(Tres::Vector3.new(0, 0, 50))
    assert_equal(Tres::Vector3.new(1, 1, 50), c)

    # exactly on the ray
    d = a.closest_point_to_point(one3)
    assert_equal(one3, d)
  end

  def test_distance_to_point
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    # behind the ray
    b = a.distance_to_point(zero3)
    assert_in_delta(Math.sqrt(3), b)

    # front of the ray
    c = a.distance_to_point(Tres::Vector3.new(0, 0, 50))
    assert_in_delta(Math.sqrt(2), c)

    # exactly on the ray
    d = a.distance_to_point(one3)
    assert_equal(0, d)
  end

  def test_is_intersection_sphere
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))
    b = Tres::Sphere.new(zero3, 0.5)
    c = Tres::Sphere.new(zero3, 1.5)
    d = Tres::Sphere.new(one3, 0.1)
    e = Tres::Sphere.new(two3, 0.1)
    f = Tres::Sphere.new(two3, 1)

    refute(a.intersection_sphere?(b))
    refute(a.intersection_sphere?(c))
    assert(a.intersection_sphere?(d))
    refute(a.intersection_sphere?(e))
    refute(a.intersection_sphere?(f))
  end

  def test_intersect_sphere
    # ray a0 origin located at (0, 0, 0) and points outward in negative-z direction
    a0 = Tres::Ray.new(zero3.clone, Tres::Vector3.new(0, 0, -1))
    # ray a1 origin located at (1, 1, 1) and points left in negative-x direction
    a1 = Tres::Ray.new(one3.clone, Tres::Vector3.new(-1, 0, 0))

    # sphere (radius of 2) located behind ray a0, should result in nil
    b = Tres::Sphere.new(Tres::Vector3.new(0, 0, 3), 2)
    assert_equal(nil, a0.intersect_sphere(b))

    # sphere (radius of 2) located in front of, but too far right of ray a0, should result in nil
    b = Tres::Sphere.new(Tres::Vector3.new(3, 0, -1), 2)
    assert_equal(nil, a0.intersect_sphere(b))

    # sphere (radius of 2) located below ray a1, should result in nil
    b = Tres::Sphere.new(Tres::Vector3.new(1, -2, 1), 2)
    assert_equal(nil, a1.intersect_sphere(b))

    # sphere (radius of 1) located to the left of ray a1, should result in intersection at 0, 1, 1
    b = Tres::Sphere.new(Tres::Vector3.new(-1, 1, 1), 1)
    intersect = a1.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 1, 1)), TOL)
    else
      assert false, "Intersect was nil"
    end

    # sphere (radius of 1) located in front of ray a0, should result in intersection at 0, 0, -1
    b = Tres::Sphere.new(Tres::Vector3.new(0, 0, -2), 1)
    intersect = a0.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 0, -1)), TOL)
    else
      assert false, "Intersect was nil"
    end

    # sphere (radius of 2) located in front & right of ray a0, should result in intersection at 0, 0, -1, or left-most edge of sphere
    b = Tres::Sphere.new(Tres::Vector3.new(2, 0, -1), 2)
    intersect = a0.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 0, -1)), TOL)
    else
      assert false, "Intersect was nil"
    end

    # same situation as above, but move the sphere a fraction more to the right, and ray a0 should now just miss
    b = Tres::Sphere.new(Tres::Vector3.new(2.01, 0, -1), 2)
    assert_equal(nil, a0.intersect_sphere(b))

    # following tests are for situations where the ray origin is inside the sphere

    # sphere (radius of 1) center located at ray a0 origin / sphere surrounds the ray origin, so the first intersect point 0, 0, 1,
    # is behind ray a0.  Therefore, second exit point on back of sphere will be returned: 0, 0, -1
    # thus keeping the intersection point always in front of the ray.
    b = Tres::Sphere.new(zero3.clone, 1)
    intersect = a0.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 0, -1)), TOL)
    else
      assert false, "Intersect was nil"
    end

    # sphere (radius of 4) center located behind ray a0 origin / sphere surrounds the ray origin, so the first intersect point 0, 0, 5,
    # is behind ray a0.  Therefore, second exit point on back of sphere will be returned: 0, 0, -3
    # thus keeping the intersection point always in front of the ray.
    b = Tres::Sphere.new(Tres::Vector3.new(0, 0, 1), 4)
    intersect = a0.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 0, -3)), TOL)
    else
      assert false, "Intersect was nil"
    end

    # sphere (radius of 4) center located in front of ray a0 origin / sphere surrounds the ray origin, so the first intersect point 0, 0, 3,
    # is behind ray a0.  Therefore, second exit point on back of sphere will be returned: 0, 0, -5
    # thus keeping the intersection point always in front of the ray.
    b = Tres::Sphere.new(Tres::Vector3.new(0, 0, -1), 4)
    intersect = a0.intersect_sphere(b)
    unless intersect.nil?
      assert_in_delta(0, intersect.distance_to(Tres::Vector3.new(0, 0, -5)), TOL)
    else
      assert false, "Intersect was nil"
    end

  end

  def test_is_intersection_plane
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    # parallel plane in front of the ray
    b = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), one3.clone.sub(Tres::Vector3.new(0, 0, -1)))
    assert(a.intersection_plane?(b))

    # parallel plane coincident with origin
    c = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), one3.clone.sub(Tres::Vector3.new(0, 0, 0)))
    assert(a.intersection_plane?(c))

    # parallel plane behind the ray
    d = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), one3.clone.sub(Tres::Vector3.new(0, 0, 1)))
    refute(a.intersection_plane?(d))

    # perpendical ray that overlaps exactly
    e = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(1, 0, 0), one3)
    assert(a.intersection_plane?(e))

    # perpendical ray that doesn't overlap
    f = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(1, 0, 0), zero3)
    refute(a.intersection_plane?(f))
  end

  def test_intersect_plane
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))

    # parallel plane behind
    b = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), Tres::Vector3.new(1, 1, -1))
    assert_equal(nil, a.intersect_plane(b))

    # parallel plane coincident with origin
    c = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), Tres::Vector3.new(1, 1, 0))
    assert_equal(nil, a.intersect_plane(c))

    # parallel plane infront
    d = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(0, 0, 1), Tres::Vector3.new(1, 1, 1))
    assert_equal(a.origin, a.intersect_plane(d))

    # perpendical ray that overlaps exactly
    e = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(1, 0, 0), one3)
    assert_equal(a.origin, a.intersect_plane(e))

    # perpendical ray that doesn't overlap
    f = Tres::Plane.new.set_from_normal_and_coplanar_point(Tres::Vector3.new(1, 0, 0), zero3)
    assert_equal(nil, a.intersect_plane(f))
  end

  def test_apply_matrix4
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))
    m = Tres::Matrix4.new

    assert_equal(a, a.clone.apply_matrix4(m))

    a = Tres::Ray.new(zero3.clone, Tres::Vector3.new(0, 0, 1))
    m.make_rotation_z(Math::PI)
    assert_equal(a, a.clone.apply_matrix4(m))

    m.make_rotation_x(Math::PI)
    b = a.clone
    b.direction.negate
    a2 = a.clone.apply_matrix4(m)
    assert_in_delta(a2.origin.distance_to(b.origin), TOL)
    assert_in_delta(0, a2.direction.distance_to(b.direction), TOL)

    a.origin = Tres::Vector3.new(0, 0, 1)
    b.origin = Tres::Vector3.new(0, 0, -1)
    a2 = a.clone.apply_matrix4(m)
    assert_in_delta(0, a2.origin.distance_to(b.origin), TOL)
    assert_in_delta(0, a2.direction.distance_to(b.direction), TOL)
  end

  def test_distance_sq_to_segment
    a = Tres::Ray.new(one3.clone, Tres::Vector3.new(0, 0, 1))
    ptOnLine = Tres::Vector3.new
    ptOnSegment = Tres::Vector3.new

    #segment in front of the ray
    v0 = Tres::Vector3.new(3, 5, 50)
    v1 = Tres::Vector3.new(50, 50, 50) # just a far away point
    distSqr = a.distance_sq_to_segment(v0, v1, ptOnLine, ptOnSegment)

    assert_in_delta(0, ptOnSegment.distance_to(v0), TOL)
    assert_in_delta(0, ptOnLine.distance_to(Tres::Vector3.new(1, 1, 50)), TOL)
    # ((3-1) * (3-1) + (5-1) * (5-1) = 4 + 16 = 20
    assert_in_delta(20, distSqr, TOL)

    #segment behind the ray
    v0 = Tres::Vector3.new(-50, -50, -50) # just a far away point
    v1 = Tres::Vector3.new(-3, -5, -4)
    distSqr = a.distance_sq_to_segment(v0, v1, ptOnLine, ptOnSegment)

    assert_in_delta(0, ptOnSegment.distance_to(v1), TOL)
    assert_in_delta(0, ptOnLine.distance_to(one3), TOL)
    # ((-3-1) * (-3-1) + (-5-1) * (-5-1) + (-4-1) + (-4-1) = 16 + 36 + 25 = 77
    assert_in_delta(77, distSqr, TOL)

    #exact intersection between the ray and the segment
    v0 = Tres::Vector3.new(-50, -50, -50)
    v1 = Tres::Vector3.new(50, 50, 50)
    distSqr = a.distance_sq_to_segment(v0, v1, ptOnLine, ptOnSegment)

    assert_in_delta(0, ptOnSegment.distance_to(one3), TOL)
    assert_in_delta(0, ptOnLine.distance_to(one3), TOL)
    assert_in_delta(0, distSqr, TOL)
  end

  def test_intersect_box
    box = Tres::Box3.new(Tres::Vector3.new(-1, -1, -1), Tres::Vector3.new(1, 1, 1))

    a = Tres::Ray.new(Tres::Vector3.new(-2, 0, 0), Tres::Vector3.new(1, 0, 0))
    #ray should intersect box at -1,0,0
    assert a.intersection_box?(box)
    intersect = a.intersect_box(box)
    unless intersect.nil?
      assert_in_delta(intersect.distance_to(Tres::Vector3.new(-1, 0, 0)), TOL)
    else
      assert false, "Intersect was nil"
    end

    b = Tres::Ray.new(Tres::Vector3.new(-2, 0, 0), Tres::Vector3.new(-1, 0, 0))
    #ray is point away from box, it should not intersect
    refute b.intersection_box?(box)
    assert_nil b.intersect_box(box)

    c = Tres::Ray.new(Tres::Vector3.new(0, 0, 0), Tres::Vector3.new(1, 0, 0))
    # ray is inside box, should return exit point
    assert_equal(true, c.intersection_box?(box))
    intersect = c.intersect_box(box)
    unless intersect.nil?
      assert_in_delta(intersect.distance_to(Tres::Vector3.new(1, 0, 0)), TOL)
    else
      assert false, "Intersect was nil"
    end

    d = Tres::Ray.new(Tres::Vector3.new(0, 2, 1), Tres::Vector3.new(0, -1, -1).normalize)
    #tilted ray should intersect box at 0,1,0
    assert_equal(true, d.intersection_box?(box))
    intersect = d.intersect_box(box)
    unless intersect.nil?
      assert_in_delta(intersect.distance_to(Tres::Vector3.new(0, 1, 0)), TOL)
    else
      assert false, "Intersect was nil"
    end

    e = Tres::Ray.new(Tres::Vector3.new(1, -2, 1), Tres::Vector3.new(0, 1, 0).normalize)
    #handle case where ray is coplanar with one of the boxes side - box in front of ray
    assert_equal(true, e.intersection_box?(box))
    intersect = e.intersect_box(box)
    unless intersect.nil?
      assert_in_delta(intersect.distance_to(Tres::Vector3.new(1, -1, 1)), TOL)
    else
      assert false, "Intersect was nil"
    end

    f = Tres::Ray.new(Tres::Vector3.new(1, -2, 0), Tres::Vector3.new(0, -1, 0).normalize)
    #handle case where ray is coplanar with one of the boxes side - box behind ray
    refute f.intersection_box?(box)
    assert_nil f.intersect_box(box)
  end
end
