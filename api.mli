(* ************************************************************************** *)
(* Project: La Vie Est Un Jeu - Public API, example with OCaml                *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version is on GitHub: https://github.com/LaVieEstUnJeu/Public-API   *)
(* ************************************************************************** *)
(** Call the web-service to handle the API methods                            *)

open ApiTypes

(* ************************************************************************** *)
(** {3 Type}                                                                  *)
(* ************************************************************************** *)

type 'a t = 'a response

(* ************************************************************************** *)
(** {3 Network}                                                               *)
(* ************************************************************************** *)

(** Generate a formatted URL with get parameters

{b Example:} [ url ~parents:["a"; "b"] ~get:[("c", "d")] ~url:("http://g.com") ]
{b Result:}  [ http://g.com/a/b?c=d ]                                         *)
val url :
  ?parents:(string list)
  -> ?get:((string * string) list)
  -> ?url:url
  -> ?auth:(ApiTypes.auth option)
  -> ?lang:(Lang.t option)
  -> unit
  -> url

(** Handle an API method completely. Take a function to transform the json.   *)
val go :
  ?auth:(ApiTypes.auth option)
  -> ?lang:(Lang.t option)
  -> ?rtype:Network.t
  -> ?post:Network.post
  -> url
  -> (Yojson.Basic.json -> 'a)
  -> 'a t

(* ************************************************************************** *)
(** {3 Various tools}                                                         *)
(* ************************************************************************** *)

(** In case the method does not return anything on success, use this to
    handle the whole request (go + return unit result)                        *)
val noop :
  ?auth:(ApiTypes.auth option)
  -> ?lang:(Lang.t option)
  -> ?rtype:Network.t
  -> ?post:Network.post
  -> url
  -> unit t

(** Check if at least one requirement (auth or lang) has been provided before
    executing go                                                              *)
val any :
  ?auth:(ApiTypes.auth option)
  -> ?lang:(ApiTypes.Lang.t option)
  -> ?rtype:Network.t
  -> ?post:Network.post
  -> url
  -> (Yojson.Basic.json -> 'a)
  -> 'a t

(** Clean an option list by removing all the "None" elements                  *)
val option_filter :
  (string * string option) list
  -> (string * string) list

(** Methods that return an API List take two optional parameters.
    This function take both + a list of other parameters and return final list.
    {i Note that this function call option_filter.}                           *)
val pager :
  int option (* index *) -> int option (* limit *)
  -> (string * string option) list -> (string * string) list