(* ************************************************************************** *)
(* Project: La Vie Est Un Jeu - Public API, example with OCaml                *)
(* Description: Get a page from a url using curl and return a json tree       *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version is on GitHub: https://github.com/LaVieEstUnJeu/Public-API   *)
(* ************************************************************************** *)

(* ************************************************************************** *)
(* Types                                                                      *)
(* ************************************************************************** *)

type 'a t = 'a ApiTypes.response

(* ************************************************************************** *)
(* Configuration                                                              *)
(* ************************************************************************** *)

(* The URL of the API Web service                                             *)
let base_url = "http://life.paysdu42.fr:2000"

(* ************************************************************************** *)
(* Network                                                                    *)
(* ************************************************************************** *)

module type REQUESTTYPE =
sig
  type t =
    | GET
    | POST
    | PUT
    | DELETE
  val default   : t
  val to_string : t -> string
  val of_string : string -> t
end
module RequestType : REQUESTTYPE =
struct
  type t =
    | GET
    | POST
    | PUT
    | DELETE
  let default = GET
  let to_string = function
    | GET    -> "GET"
    | POST   -> "POST"
    | PUT    -> "PUT"
    | DELETE -> "DELETE"
  let of_string = function
    | "GET"    -> GET
    | "POST"   -> POST
    | "PUT"    -> PUT
    | "DELETE" -> DELETE
    | _        -> default
end

(* Return a text from a url using Curl and HTTP Auth (if needed)              *)
let get_text_form_url ?(auth=None) ?(rtype=RequestType.GET) url =
  let writer accum data =
    Buffer.add_string accum data;
    String.length data in
  let result = Buffer.create 4096
  and errorBuffer = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let text =
    try
      (let connection = Curl.init () in
       Curl.set_customrequest connection (RequestType.to_string rtype);
       Curl.set_errorbuffer connection errorBuffer;
       Curl.set_writefunction connection (writer result);
       Curl.set_followlocation connection true;
       Curl.set_url connection url;
       
       (match auth with
         | Some (username, password) ->
           (Curl.set_httpauth connection [Curl.CURLAUTH_BASIC];
            Curl.set_userpwd connection (username ^ ":" ^ password))
         | _ -> ());

       Curl.perform connection;
       Curl.cleanup connection;
       Buffer.contents result)
    with
      | Curl.CurlException (_, _, _) ->
        raise (Failure ("Error: " ^ !errorBuffer))
      | Failure s -> raise (Failure s) in
  let _ = Curl.global_cleanup () in
  text

(* Generate a formatted URL with get parameters                               *)
let url ?(parents = []) ?(get = [])
    ?(url = base_url) ?(auth = None) ?(lang = None) () =
  let get = match lang with
    | Some lang -> (("lang", ApiTypes.Lang.to_string lang)::get)
    | None      -> get in
  let get = match auth with
    | Some (ApiTypes.Token t) -> (("token", t)::get)
    | _                       -> get (* todo: OAuth stuff *) in
  let parents = List.fold_left (fun f s -> f ^ "/" ^ s) "" parents
  and get =
    let url =
      let f = (fun f (s, v) -> f ^ "&" ^ s ^ "=" ^ v) in
      (List.fold_left  f "" get) in
    if (String.length url) = 0 then url else (String.set url 0 '?'; url) in
  url ^ parents ^ get

(* ************************************************************************** *)
(* Transform content                                                          *)
(* ************************************************************************** *)

(* Take a response tree, check error and return the error and the result      *)
let get_content tree =
  let open Yojson.Basic.Util in
      let error =
        let elt = tree |> member "error" in
        if (elt |> member "code" |> to_int) = 0
        then None
        else
          (let open ApiError in
               Some {
                 message = elt |> member "message" |> to_string;
                 stype   = elt |> member "stype"   |> to_string;
                 code    = elt |> member "code"    |> to_int;
               })
      and element = tree |> member "element" in
      (error, element)

(* ************************************************************************** *)
(* Shortcuts                                                                  *)
(* ************************************************************************** *)

(* Take a url, get the page and return a json tree                            *)
let curljson ?(auth = None) ?(lang = None) ?(rtype = RequestType.GET) url =
  let result =
    get_text_form_url ~rtype:rtype
    ~auth:(match auth with
      | Some (ApiTypes.Curl auth) -> Some auth
      | _                         -> None) url in
  Yojson.Basic.from_string result

(* Take a url, get the pag into json, check and return error and result       *)
let curljsoncontent ?(auth = None) ?(lang = None)
    ?(rtype = RequestType.GET) url =
  get_content (curljson ~auth:auth ~lang:lang ~rtype:rtype url)

(* ************************************************************************** *)
(* Ultimate shortcuts                                                         *)
(* ************************************************************************** *)

(* Handle an API method completely. Take a function to transform the json.    *)
let go ?(auth = None) ?(lang = None) ?(rtype = RequestType.GET) url f =
  let (error, content) =
    curljsoncontent ~auth:auth ~lang:lang ~rtype:rtype url in
  match error with
    | Some error -> ApiTypes.Error error
    | None       -> ApiTypes.Result (f content)

(* In case the method does not return anything on success, use this to handle *)
(* the whole request (curljsoncontent + return unit result)                   *)
let noop ?(auth = None) ?(lang = None) ?(rtype = RequestType.GET) url =
  go ~auth:auth ~lang:lang ~rtype:rtype url (fun _ -> ())
