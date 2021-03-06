(* ************************************************************************** *)
(* Project: Life - the game, Official OCaml SDK                               *)
(* Author: nox                                                                *)
(* Latest Version is on GitHub: https://github.com/Life-the-game/SDK-OCaml    *)
(* ************************************************************************** *)
(** Roles API methods                                                         *)

open ApiTypes

(* PRIVATE *)
(* ************************************************************************** *)
(** {3 Type}                                                                  *)
(* ************************************************************************** *)

module type ROLE =
    sig
        type t =
            | Ambassador
            | Admin
            | Translator
            | Designer
            | Newser
         val to_string : t -> string
         val of_string : string -> t
    end
module Role : ROLE

type t =
    {
        info            : Info.t;
        role            : Role.t;
        achievements    : ApiAchievement.t list;
        lang            : string list;
    }

(* ************************************************************************** *)
(** {3 API Methods}                                                           *)
(* ************************************************************************** *)

(** Get roles                                                                 *)
val get :
    auth : auth
    -> id -> t Page.t Api.t

(** Add a role                                                                *)
val add :
    auth:auth
    -> role:Role.t
    -> ?achievements:id
    -> ?lang:string
    -> id -> t Api.t

(** Delete a role                                                             *)
val delete :
    auth:auth
    -> id
    -> unit Api.t

(* ************************************************************************** *)
(** {3 Tools}                                                                 *)
(* ************************************************************************** *)

val from_json : Yojson.Basic.json -> t

(* /PRIVATE *)
