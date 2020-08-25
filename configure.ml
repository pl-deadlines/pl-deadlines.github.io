#use "topfind"
#require "core_kernel"
#require "timezone"
open Core_kernel

let safe_remove f =
  try Sys.remove f with _ -> ()

let _ =
  let f = "today.ml" in
  safe_remove f;
  let o = Out_channel.create f in
  Out_channel.fprintf o "let time = \"%s\"" (Time_ns.now () |> Time_ns.to_string_abs_trimmed ~zone:(Lazy.force (Timezone.local)))
