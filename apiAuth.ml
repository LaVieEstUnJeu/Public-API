(* ************************************************************************** *)
(* Project: Life - the game, Official OCaml SDK                               *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version is on GitHub: https://github.com/Life-the-game/SDK-OCaml    *)
(* ************************************************************************** *)

open ApiTypes
open Network

(* ************************************************************************** *)
(* Type                                                                       *)
(* ************************************************************************** *)

type t =
    {
      info           : Info.t;
      mutable user   : ApiUser.t;
(* PRIVATE *)
      (* ip             : ip; *)
      (* user_agent     : string; *)
(* /PRIVATE *)
      token          : token;
      expiration     : DateTime.t;
      (* facebook_token : string option; *)
    }

(* ************************************************************************** *)
(* Tools                                                                      *)
(* ************************************************************************** *)

let from_json content =
  let open Yojson.Basic.Util in
      {
        info       = Info.from_json content;
        user       = ApiUser.from_json (content |> member "user");
(* PRIVATE *)
        (* ip         = content |> member "ip" |> to_string; *)
        (* user_agent = content |> member "user_agent" |> to_string; *)
(* /PRIVATE *)
        token      = content |> member "token" |> to_string;
        expiration = DateTime.of_string
          (content |> member "expiration" |> to_string);
        (* facebook_token = content |> member "facebook_token" *)
        (*   |> to_string_option; *)
      }

(* Transform an API object returned by the login function into an api type
   required by most of the API methods                                        *)
let auth_to_api auth =
  Token auth.token

let opt_auth_to_api = function
  | Some auth -> Some (auth_to_api auth)
  | None      -> None

(* ************************************************************************** *)
(* API Methods                                                                *)
(* ************************************************************************** *)

(* ************************************************************************** *)
(* Login (create token)                                                       *)
(* ************************************************************************** *)

let login
(* PRIVATE *)
    ?(ip = "")
(* /PRIVATE *)
    login password =
  Api.go
    ~rtype:POST
    ~path:["users"; login; "tokens"]
    ~post:(Network.PostList
             (Network.option_filter
                [("password", Some password);
(* PRIVATE *)
                 ("ip", Some ip)
(* /PRIVATE *)
                ]))
    from_json

(* ************************************************************************** *)
(* OAuth                                                                      *)
(* ************************************************************************** *)

let oauth provider token =
  Api.go
    ~rtype:POST
    ~path:["oauth"; "external"]
    ~post:(PostList [("site_name", "facebook");
		     ("site_token", token)])
    from_json

let facebook =
  oauth "facebook"

(* ************************************************************************** *)
(* Logout (delete token)                                                      *)
(* ************************************************************************** *)

let logout auth =
  Api.go
    ~rtype:DELETE
    ~path:["users"; auth.user.ApiUser.info.Info.id;
           "tokens"; auth.token]
    Api.noop

