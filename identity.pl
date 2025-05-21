package identity;

use JSON::PP;
use MIME::Base64;

sub set_identity_header {
    my $cert_template = {
        'identity' => {
            'org_id' => '',
            'internal' => {
                'org_id' => ''
            },
            'type' => 'System',
            'auth_type' => 'cert-auth',
            'system' => {
                'cn' => '',
                'cert_type' => 'satellite'
            }
        }
    };

    my $identity;
    my $r = shift;

    my $ssl_client_s_dn = $r->variable("ssl_client_s_dn");

    if (!$ssl_client_s_dn || $ssl_client_s_dn eq "") {
        $r->log_error("Missing client certificate subject");
        return undef;
    }

    # Extract org_id (O) and CN from the certificate subject
    my $org_id;
    my $cn;

    if ($ssl_client_s_dn =~ /O=([^,]+)/) {
        $org_id = $1;
    } else {
        $r->log_error("Missing O (org_id) in client certificate subject: $ssl_client_s_dn");
        return undef;
    }

    if ($ssl_client_s_dn =~ /CN=([^,]+)/) {
        $cn = $1;
    } else {
        $r->log_error("Missing CN in client certificate subject: $ssl_client_s_dn");
        return undef;
    }

    $cert_template->{identity}->{system}->{cn} = $cn;
    $cert_template->{identity}->{org_id} = $org_id;
    $cert_template->{identity}->{internal}->{org_id} = $org_id;
    $identity = encode_base64(encode_json($cert_template), '');

    return $identity;
}

1;