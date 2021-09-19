open! Base
open! Scad_ml
open! Generator

let lookups =
  let offset = function
    | 2 -> 0., 3.5, -5. (* middle *)
    | 3 -> 1., -2.5, 0.5 (* ring *)
    | i when i >= 4 -> 0.5, -18., 8.5 (* pinky *)
    | 0 -> -2., 0., 5.5
    | _ -> 0., 0., 0.
  and curve = function
    | i when i >= 3 ->
      Curvature.(curve ~well:(spec ~radius:36. (Float.pi /. 4.25)) ())
      (* ring and pinky *)
    | i when i = 0 ->
      Curvature.(
        curve ~well:(spec ~tilt:(Float.pi /. 7.5) ~radius:45. (Float.pi /. 5.95)) ())
    | _ -> Curvature.(curve ~well:(spec ~radius:45.5 (Float.pi /. 6.1)) ())
  and splay = function
    | i when i = 3 -> Float.pi /. -25. (* ring *)
    | i when i >= 4 -> Float.pi /. -11. (* pinky *)
    | _ -> 0.
  and rows _ = 3 in
  Plate.Lookups.make ~offset ~curve ~splay ~rows ()

let plate_builder =
  Plate.make
    ~n_cols:5
    ~lookups
    ~thumb_curve:
      Curvature.(
        curve
          ~fan:{ angle = Float.pi /. 9.; radius = 70.; tilt = Float.pi /. 48. }
          ~well:{ angle = Float.pi /. 7.5; radius = 47.; tilt = 0. }
          ())
    ~thumb_offset:(-18., -40., 12.)
    ~thumb_angle:Float.(pi /. 30., pi /. -9., pi /. 12.)
    ~caps:Caps.Matty3.row
    ~thumb_caps:Caps.MT3.thumb_1u

let wall_builder plate =
  Walls.
    { body =
        Body.make
          ~n_steps:(`Flat 3)
          ~north_clearance:2.5
          ~south_clearance:2.5
          ~side_clearance:1.5
          plate
    ; thumb =
        Thumb.make
          ~south_lookup:(fun _ -> Yes)
          ~east:No
          ~west:Screw
          ~clearance:2.0
          ~n_steps:(`Flat 3)
          plate
    }

let base_connector =
  Connect.skeleton
    ~n_facets:1
    ~height:9.
    ~thumb_height:11.
    ~east_link:(Connect.snake ~height:11. ~scale:1.5 ~d:1.2 ())
    ~west_link:(Connect.straight ~height:11. ())
    ~cubic_d:2.
    ~cubic_scale:1.5
    ~body_join_steps:3
    ~thumb_join_steps:3
    ~fudge_factor:8.
    ~close_thumb:true
    ~pinky_elbow:false
    ~overlap_factor:1.

let plate_welder plate =
  Model.union [ Plate.skeleton_bridges plate; Bridge.cols ~columns:plate.columns 1 2 ]

let ports_cutter = BastardShield.(cutter ~x_off:1. ~y_off:(-1.) (make ()))

let build ?right_hand ?hotswap () =
  Case.make
    ?right_hand
    ~plate_builder
    ~plate_welder
    ~wall_builder
    ~base_connector
    ~ports_cutter
    (Mx.make_hole ?hotswap ~clearance:2. ())

let bastard_compare () =
  Model.union
    [ Skeletyl.bastard_skelly
    ; Case.to_scad ~show_caps:false (build ()) |> Model.color ~alpha:0.5 Color.Yellow
    ]
