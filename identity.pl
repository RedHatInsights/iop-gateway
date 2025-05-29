package identity;

use JSON::PP;
use MIME::Base64;

sub set_identity_header {
    my $identity;
    my $r = shift;

    my $ssl_client_s_dn = $r->variable("ssl_client_s_dn");

    if (!$ssl_client_s_dn || $ssl_client_s_dn eq "") {
        $r->log_error(0, "Missing client certificate subject");
        return undef;
    }

    # Extract org_id (O) and CN from the certificate subject
    my $org_id;
    my $cn;

    if ($ssl_client_s_dn =~ /O=([^,]+)/) {
        $org_id = $1;
    } else {
        $r->log_error(0, "Missing O (org_id) in client certificate subject: $ssl_client_s_dn");
        return undef;
    }

    if ($ssl_client_s_dn =~ /CN=([^,]+)/) {
        $cn = $1;
    } else {
        $r->log_error(0, "Missing CN in client certificate subject: $ssl_client_s_dn");
        return undef;
    }

    my $forwarded = $r->header_in("Forwarded"); # RFC 7239
    if (!$forwarded || $forwarded eq "") {
        # Use User identity for non-forwarded requests
        $identity = {
            'identity' => {
                'auth_type' => 'jwt-auth',
                'org_id' => $org_id,
                'internal' => {
                    'org_id' => $org_id
                },
                'type' => 'User',
                'user' => {
                    'email' => 'iop-gateway@example.com',
                    'first_name' => 'First',
                    'is_active' => JSON::PP::true,
                    'is_internal' => JSON::PP::true,
                    'is_org_admin' => JSON::PP::false,
                    'last_name' => 'Last',
                    'locale' => 'en_US',
                    'user_id' => '1',
                    'username' => $cn
                }
            }
        };
    } else {
        # Use System identity for forwarded requests
        $identity = {
            'identity' => {
                'org_id' => $org_id,
                'internal' => {
                    'org_id' => $org_id
                },
                'type' => 'System',
                'auth_type' => 'cert-auth',
                'system' => {
                    'cn' => $cn,
                    'cert_type' => 'satellite'
                }
            }
        };
    }

    return encode_base64(encode_json($identity), '');
}

1;