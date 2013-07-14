(* ************************************************************************** *)
(* Project: La Vie Est Un Jeu - Public API, example with OCaml                *)
(* Description: tools to get/edit users                                       *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version is on GitHub: https://github.com/LaVieEstUnJeu/Public-API   *)
(* ************************************************************************** *)

open ApiTypes
open Network

(* ************************************************************************** *)
(* Types                                                                      *)
(* ************************************************************************** *)

type t =
    {
      info               : Info.t;
      login              : login;
      firstname          : string option;
      lastname           : string option;
      avatar             : ApiMedia.Picture.t option;
      gender             : Gender.t;
      birthday           : Date.t option;
      is_friend          : bool option;
      url                : url;
      lang               : Lang.t;
    }

(* ************************************************************************** *)
(* Tools                                                                      *)
(* ************************************************************************** *)

(* Take a json tree representing a user and return an object user             *)
let from_json c =
  let open Yojson.Basic.Util in
  let open ApiMedia in
      {
	info        = Info.from_json c;
	login       = c |> member "login" |> to_string;
	firstname   = c |> member "firstname" |> to_string_option;
	lastname    = c |> member "lastname" |> to_string_option;
	avatar      = c |> member "avatar" |> to_option Picture.from_json;
	gender      = Gender.of_string (c |> member "gender" |> to_string);
	birthday    = c |> member "birthday" |> to_option
	    (fun d -> Date.of_string (d |> to_string));
	is_friend   = c |> member "is_friend" |> to_bool_option;
	url         = c |> member "url" |> to_string;
	lang        = Lang.from_string (c |> member "lang" |> to_string);
      }

let name user =
  let optstr = function | Some s -> s | None   -> "" in
  ((optstr user.firstname) ^  " " ^ (optstr user.lastname))

(* ************************************************************************** *)
(* Api Methods                                                                *)
(* ************************************************************************** *)

(* ************************************************************************** *)
(* Create a user                                                              *)
(* ************************************************************************** *)

let create ~login ~email ~password ~lang ?(firstname = None) ?(lastname = None)
    ?(gender = None) ?(birthday = None) () =
  let url = Api.url ~parents:["users"] ~lang:(Some lang) () in
  Api.go ~rtype:POST ~lang:(Some lang)
    ~post:(PostList (Api.option_filter
		       [("login", Some login);
			("email", Some email);
			("password", Some password);
			("firstname", firstname);
			("lastname", lastname);
			("gender", Option.map Gender.to_string gender);
			("birthday", Option.map Date.to_string birthday);
		       ])) url from_json

(* ************************************************************************** *)
(* Get users                                                                  *)
(* ************************************************************************** *)

let get ~auth ?(term = None) ?(index = None) ?(limit = None) () =
  let url = Api.url ~parents:["users"] ~auth:(Some auth)
    ~get:(Api.pager index limit [("term", term)]) () in
  Api.go ~auth:(Some auth) url (ApiTypes.List.from_json from_json)

(* ************************************************************************** *)
(* Get a user                                                                 *)
(* ************************************************************************** *)

let get_user ?(auth = None) ?(lang = None) id =
  let url = Api.url ~parents:["users"; id] ~auth:auth ~lang:lang () in
  Api.any ~auth:auth ~lang:lang url from_json

(* ************************************************************************** *)
(* Delete a user                                                              *)
(* ************************************************************************** *)

let delete ~auth id =
  let url = Api.url ~parents:["users"; id] ~auth:(Some auth) () in
  Api.noop ~auth:(Some auth) ~rtype:DELETE url

(* ************************************************************************** *)
(* Edit (put) a user                                                          *)
(* ************************************************************************** *)

let edit ~auth ?(email = None) ?(password = None) ?(firstname = None)
    ?(lastname = None) ?(gender = None) ?(birthday = None) id =
  let url = Api.url ~parents:["users"; id] ~auth:(Some auth)
    ~get:(Api.option_filter
	    [("email", email);
	     ("password", password);
	     ("firstname", firstname);
	     ("lastname", lastname);
	     ("gender", Option.map Gender.to_string gender);
	     ("birthday", Option.map Date.to_string birthday);
	    ]) () in
  Api.go ~auth:(Some auth) ~rtype:PUT url from_json

(* ************************************************************************** *)
(* Get user's friends                                                         *)
(* ************************************************************************** *)

let get_friends ?(auth = None) ?(lang = None)
    ?(index = None) ?(limit = None) user_id =
  let url = Api.url ~parents:["users"; user_id; "friends"] ~auth:auth ~lang:lang
    ~get:(Api.pager index limit []) () in
  Api.any ~auth:auth ~lang:lang url (ApiTypes.List.from_json from_json)

(* ************************************************************************** *)
(* The authenticated user request a friendship with a user                    *)
(*   Note: The src_user is for administrative purpose only                    *)
(* ************************************************************************** *)

let be_friend_with ~auth ?(src_user = None) user_id =
  let url =
    Api.url ~parents:["users"; user_id; "friends"] ~auth:(Some auth) () in
  Api.noop ~auth:(Some auth) ~rtype:POST
    ~post:(PostList (Api.option_filter [("src_user_id", src_user)])) url

(* ************************************************************************** *)
(* The authenticated user delete a friendship with a user                     *)
(* ************************************************************************** *)

let dont_be_friend_with ~auth user_id =
  Api.noop ~auth:(Some auth) ~rtype:DELETE
    (Api.url ~parents:["users"; user_id; "friends"] ~auth:(Some auth) ())

(* ************************************************************************** *)
(* Delete a friendship between a user and another user                        *)
(*   Note: This method is for administrative purpose only                     *)
(* ************************************************************************** *)

let delete_friendship ~auth user_id user_in_list_id =
  let url = Api.url ~auth:(Some auth)
    ~parents:["users"; user_id; "friends"; user_in_list_id] () in
  Api.noop ~auth:(Some auth) ~rtype:DELETE url