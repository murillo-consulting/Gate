# Issues a GET against a POST-only endpoint.
# Gate must respond with 405 Method Not Allowed.
# The Allow response header should indicate POST is the accepted method.
GET http://{{host}}/v1/chat/completions
Authorization: Bearer {{jwt_default}}
HTTP 405
