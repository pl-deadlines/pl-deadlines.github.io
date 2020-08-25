open Core_kernel

let content =
  let chan = In_channel.create "events.json" in
  let content = Ezjsonm.from_channel chan in
  let _ = In_channel.close chan in
  content

let tags =
  Ezjsonm.find content ["tags"] |> Ezjsonm.get_strings

type event =
  {
    name: string;
    abbrv: string;
    year: string;
    url: string;
    date: string;
    location: string;
    deadline: Time_ns.t;
    tags: string list;
    notes: string;
    is_conf: bool
  }

let parse_event b v =
  {
    name = Ezjsonm.find v ["name"] |> Ezjsonm.get_string;
    abbrv = Ezjsonm.find v ["abbrv"] |> Ezjsonm.get_string;
    year = Ezjsonm.find v ["year"] |> Ezjsonm.get_string;
    url = Ezjsonm.find v ["url"] |> Ezjsonm.get_string;
    date = Ezjsonm.find v ["date"] |> Ezjsonm.get_string;
    location = Ezjsonm.find v ["location"] |> Ezjsonm.get_string;
    deadline = Ezjsonm.find v ["deadline"] |> Ezjsonm.get_string |> Time_ns.of_string;
    tags = Ezjsonm.find v ["tags"] |> Ezjsonm.get_strings;
    notes = Ezjsonm.find v ["notes"] |> Ezjsonm.get_string;
    is_conf = b
  }

let confs =
  Ezjsonm.find content ["conferences"] |> Ezjsonm.get_list (parse_event true)

let workshops =
  Ezjsonm.find content ["workshops"] |> Ezjsonm.get_list (parse_event false)

type tag = { name: string; is_visible: bool }

type model =
  {
    conf_visible: bool;
    workshops_visible: bool;
    tags: tag list;
    events_live: event list;
    events_past: event list
  }

type 'msg Vdom.Cmd.t +=
  | Tick of 'msg

let init =
  let events_live, events_past = List.sort ~compare:(fun c1 c2 -> Time_ns.compare c1.deadline c2.deadline) (List.append confs workshops) |> List.partition_tf ~f:(fun ev -> Time_ns.is_later ev.deadline ~than:(Time_ns.now ())) in
  { conf_visible = true;
    workshops_visible = true;
    tags = List.map ~f:(fun t -> { name = t; is_visible = true }) tags;
    events_live = events_live;
    events_past = events_past |> List.rev
  } |> Vdom.return ~c:[Tick `Redraw]

open Vdom

let render_tag { name; is_visible } =
  elt "button" [text name]
    ~a:[class_ (if is_visible then "button is-success" else "button is-danger is-outlined");
        onclick (fun _ -> `Change name)
       ]

let render_tags tags =
  div ~a:[class_ "buttons has-addons is-centered"]
    (List.map ~f:render_tag tags)

let render_conf_workshops conf_visible workshops_visible =
  div ~a:[class_ "buttons has-addons is-centered"]
    [elt "button" [text "Conference"]
       ~a:[class_ (if conf_visible then "button is-success" else "button is-danger is-outlined");
           onclick (fun _ -> `ChangeConf)
          ];
     elt "button" [text "Workshops"]
       ~a:[class_ (if workshops_visible then "button is-success" else "button is-danger is-outlined");
           onclick (fun _ -> `ChangeWorkshops)
          ]
    ]

let tag_equal tag1 tag2 =
  String.(=) tag1.name tag2.name && tag1.is_visible && tag2.is_visible

let is_visible_event conf_visible workshops_visible tags event =
  ((event.is_conf && conf_visible) || (not event.is_conf && workshops_visible)) &&
  (List.is_empty event.tags || List.fold event.tags ~init:false ~f:(fun b tag -> b || List.mem tags { name = tag; is_visible = true } tag_equal))

let render_event conf_visible workshops_visible tags event =
  if is_visible_event conf_visible workshops_visible tags event
  then div ~a:[class_ (if Time_ns.is_earlier event.deadline (Time_ns.now ()) then "columns has-text-grey-lighter" else "columns")]
      [div ~a:[class_ "column is-half"]
         [elt "a" [text (event.abbrv ^ " " ^ event.year)]
            ~a:[class_ "has-text-weight-bold is-size-4";
                str_prop "href" event.url
               ];
          elt "p" [text event.name];
          elt "p" [text (event.date ^ " | " ^ event.location)];
          elt "p" [text event.notes]
         ];
       div ~a:[class_ "column"]
         [elt "p" [text (Time_ns.diff event.deadline (Time_ns.now ()) |> Time_ns.Span.to_string)]
            ~a:[class_ "has-text-weight-bold is-size-2"];
          elt "p" [text ("Deadline: " ^ (event.deadline |> Time_ns.to_string_abs_trimmed ~zone:(Lazy.force (Timezone.local))))];
          elt "p" [text (if List.is_empty event.tags then "" else ("Tags: " ^ (if List.length event.tags > 1 then List.fold (List.tl_exn event.tags) ~init:(List.hd_exn event.tags) ~f:(fun a b -> a ^ ", " ^ b) else List.hd_exn event.tags)))]
         ]
      ]
  else div ~a:[] []

let render_events conf_visible workshops_visible tags events =
  div ~a:[]
    (List.map ~f:(render_event conf_visible workshops_visible tags) events)

let view { conf_visible; workshops_visible; tags; events_live; events_past } =
  div ~a:[class_ "container"]
    [ elt "h1" [text "Programming Languages Conferences Deadlines"]
        ~a:[class_ "title is-centered is-1"];
      elt "p" [text "To add/update a deadline, ";
               elt "a" [text "send in a pull request"]
                 ~a:[str_prop "href" "https://github.com/pl-deadlines/pl-deadlines.github.io"];
               text "."
              ];
      elt "p" [text ("Last update: " ^ Today.time)] ~a:[class_ "pb-5"];
      div ~a:[]
        [render_conf_workshops conf_visible workshops_visible;
         render_tags tags
        ];
      elt "p" [] ~a:[class_ "pb-6"];
      render_events conf_visible workshops_visible tags events_live;
      render_events conf_visible workshops_visible tags events_past
    ]

let update model = function
  | `Change s ->
    let new_tags = List.map ~f:(fun {name; is_visible} -> {name = name; is_visible = if String.equal name s then not is_visible else is_visible}) model.tags in
    return { model with tags = new_tags }
  | `ChangeConf -> return { model with conf_visible = not model.conf_visible }
  | `ChangeWorkshops -> return { model with workshops_visible = not model.workshops_visible }
  | `Redraw -> return model ~c:[Tick `Redraw]

open Js_browser

let cmd_handler ctx = function
  | Tick msg ->
    ignore (Window.set_timeout window (fun () -> Vdom_blit.Cmd.send_msg ctx msg) 200);
    true
  | _ ->
    false

let () = Vdom_blit.(register (cmd {f = cmd_handler}))

let app = app ~init ~update ~view ()

open Js_browser

let run () =
  Vdom_blit.run app
  |> Vdom_blit.dom
  |> Element.append_child (Document.body document)

let () = Window.set_onload window run
