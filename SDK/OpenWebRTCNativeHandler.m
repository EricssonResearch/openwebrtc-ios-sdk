//
//  OpenWebRTCNativeHandler.h
//
//  Copyright (c) 2015, Ericsson AB.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this
//  list of conditions and the following disclaimer in the documentation and/or other
//  materials provided with the distribution.

//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
//  OF SUCH DAMAGE.
//

#import "OpenWebRTCNativeHandler.h"
#import "OpenWebRTCUtils.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "owr.h"
#include "owr_audio_payload.h"
#include "owr_audio_renderer.h"
//#include "owr_local.h"
#include "owr_media_session.h"
#include "owr_transport_agent.h"
#include "owr_video_payload.h"
#include "owr_video_renderer.h"
#include "owr_window_registry.h"

//#include <gio/gio.h>
//#include <string.h>

#define SELF_VIEW_TAG "self-view"
#define REMOTE_VIEW_TAG "remote-view"

OwrVideoRenderer *renderer;

static OpenWebRTCNativeHandler *staticSelf;

@interface OpenWebRTCNativeHandler ()

@property (nonatomic, strong) NSMutableArray *helperServers;

@end

@implementation OpenWebRTCNativeHandler

#pragma mark - Public methods.

- (instancetype)initWithDelegate:(id <OpenWebRTCNativeHandlerDelegate>)delegate
{
    if (self = [super init]) {
        owr_init();
        staticSelf = self;
        self.delegate = delegate;
    }
    return self;
}

- (void)setSelfView:(OpenWebRTCVideoView *)selfView
{
    owr_window_registry_register(owr_window_registry_get(), SELF_VIEW_TAG, (__bridge gpointer)(selfView));
}

- (void)setRemoteView:(OpenWebRTCVideoView *)remoteView
{
    owr_window_registry_register(owr_window_registry_get(), REMOTE_VIEW_TAG, (__bridge gpointer)(remoteView));
}

- (void)addSTUNServerWithAddress:(NSString *)address port:(NSInteger)port
{
    NSDictionary *stun = @{@"address": address,
                           @"port": [NSNumber numberWithInteger:port],
                           @"type": [NSNumber numberWithInt:OWR_HELPER_SERVER_TYPE_STUN]};
    [self.helperServers addObject:stun];
}

- (void)addTURNServerWithAddress:(NSString *)address port:(NSInteger)port username:(NSString *)username password:(NSString *)password isTCP:(BOOL)isTCP
{
    NSDictionary *turn = @{@"address": address,
                           @"port": [NSNumber numberWithInteger:port],
                           @"type": [NSNumber numberWithInt:isTCP ? OWR_HELPER_SERVER_TYPE_TURN_TCP : OWR_HELPER_SERVER_TYPE_TURN_UDP],
                           @"username": username,
                           @"password": password};
    [self.helperServers addObject:turn];
}

- (void)initiateCall
{
    NSLog(@"WARNING! initiateCall Not yet implemented");
}

- (void)terminateCall
{
    NSLog(@"WARNING! terminateCall Not yet implemented");
}

#pragma mark - Private methods.

- (NSMutableArray *)helperServers
{
    if (!_helperServers) {
        _helperServers = [NSMutableArray array];
    }
    return _helperServers;
}

- (void)handleOfferReceived:(NSString *)offer
{
    NSDictionary *sdp = [OpenWebRTCUtils parseSDPFromString:offer];
    NSLog(@"Parsed Offer SDP: %@", sdp);

    const gchar *mtype;
    OwrMediaType media_type = OWR_MEDIA_TYPE_UNKNOWN;
    gboolean rtcp_mux;
    OwrMediaSession *media_session;
    GObject *session;
    gint64 payload_type, clock_rate, channels = 0;
    const gchar *encoding_name;
    gboolean ccm_fir = FALSE, nack_pli = FALSE;
    OwrCodecType codec_type;
    OwrCandidate *remote_candidate;
    OwrComponentType component_type;
    const gchar *ice_ufrag, *ice_password;
    OwrPayload *send_payload, *receive_payload;
    GList *list_item;
    OwrMediaSource *source;
    OwrMediaType source_media_type;
    GList *media_sessions;

    for (NSDictionary *mediaDescription in sdp[@"mediaDescriptions"]) {
        media_session = owr_media_session_new(TRUE);
        session = G_OBJECT(media_session);

        mtype = [mediaDescription[@"type"] UTF8String];
        g_object_set_data(session, "media-type", g_strdup(mtype));

        rtcp_mux = [mediaDescription[@"rtcp"][@"mux"] boolValue];
        g_object_set(media_session, "rtcp-mux", rtcp_mux, NULL);

        NSArray *payloads = mediaDescription[@"payloads"];
        codec_type = OWR_CODEC_TYPE_NONE;
        for (int j = 0; j < [payloads count] && codec_type == OWR_CODEC_TYPE_NONE; j++) {
            NSDictionary *payload = payloads[j];

            encoding_name = [payload[@"encodingName"] UTF8String];
            payload_type = [payload[@"type"] intValue];
            clock_rate = [payload[@"clockRate"] intValue];

            send_payload = receive_payload = NULL;
            if (!g_strcmp0(mtype, "audio")) {
                media_type = OWR_MEDIA_TYPE_AUDIO;
                if (!g_strcmp0(encoding_name, "PCMA"))
                    codec_type = OWR_CODEC_TYPE_PCMA;
                else if (!g_strcmp0(encoding_name, "PCMU"))
                    codec_type = OWR_CODEC_TYPE_PCMU;
                else if (!g_strcmp0(encoding_name, "OPUS") || !g_strcmp0(encoding_name, "opus"))
                    codec_type = OWR_CODEC_TYPE_OPUS;
                else
                    continue;

                channels = [payload[@"channels"] intValue];

                send_payload = owr_audio_payload_new(codec_type, payload_type, clock_rate,
                                                     channels);
                receive_payload = owr_audio_payload_new(codec_type, payload_type, clock_rate,
                                                        channels);
            } else if (!g_strcmp0(mtype, "video")) {
                media_type = OWR_MEDIA_TYPE_VIDEO;
                if (!g_strcmp0(encoding_name, "H264"))
                    codec_type = OWR_CODEC_TYPE_H264;
                else if (!g_strcmp0(encoding_name, "VP8"))
                    codec_type = OWR_CODEC_TYPE_VP8;
                else
                    continue;

                ccm_fir = [payload[@"ccmfir"] boolValue];
                nack_pli = [payload[@"nackpli"] boolValue];

                send_payload = owr_video_payload_new(codec_type, payload_type, clock_rate,
                                                     ccm_fir, nack_pli);
                receive_payload = owr_video_payload_new(codec_type, payload_type, clock_rate,
                                                        ccm_fir, nack_pli);
            } else
                g_warn_if_reached();

            if (send_payload && receive_payload) {
                g_object_set_data(session, "encoding-name", g_strdup(encoding_name));
                g_object_set_data(session, "payload-type", GUINT_TO_POINTER(payload_type));
                g_object_set_data(session, "clock-rate", GUINT_TO_POINTER(clock_rate));
                if (OWR_IS_AUDIO_PAYLOAD(send_payload))
                    g_object_set_data(session, "channels", GUINT_TO_POINTER(channels));
                else if (OWR_IS_VIDEO_PAYLOAD(send_payload)) {
                    g_object_set_data(session, "ccm-fir", GUINT_TO_POINTER(ccm_fir));
                    g_object_set_data(session, "nack-pli", GUINT_TO_POINTER(nack_pli));
                } else
                    g_warn_if_reached();

                owr_media_session_add_receive_payload(media_session, receive_payload);
                owr_media_session_set_send_payload(media_session, send_payload);
            }
        }
        ice_ufrag = [mediaDescription[@"ice"][@"ufrag"] UTF8String];
        g_object_set_data_full(session, "remote-ice-ufrag", g_strdup(ice_ufrag), g_free);
        ice_password = [mediaDescription[@"ice"][@"password"] UTF8String];
        g_object_set_data_full(session, "remote-ice-password", g_strdup(ice_password), g_free);

        NSArray *candidates = mediaDescription[@"candidates"];
        if (candidates) {
            for (NSDictionary *candidate in candidates) {
                remote_candidate = [OpenWebRTCNativeHandler candidateFromObject:candidate];
                g_object_set(remote_candidate, "ufrag", ice_ufrag, "password", ice_password, NULL);
                g_object_get(remote_candidate, "component-type", &component_type, NULL);
                if (!rtcp_mux || component_type != OWR_COMPONENT_TYPE_RTCP)
                    owr_session_add_remote_candidate(OWR_SESSION(media_session), remote_candidate);
                else
                    g_object_unref(remote_candidate);
            }
        }

        g_signal_connect(media_session, "on-incoming-source", G_CALLBACK(got_remote_source), NULL);
        g_signal_connect(media_session, "on-new-candidate", G_CALLBACK(got_candidate), NULL);
        g_signal_connect(media_session, "on-candidate-gathering-done", G_CALLBACK(candidate_gathering_done), NULL);
        g_signal_connect(media_session, "notify::dtls-certificate", G_CALLBACK(got_dtls_certificate), NULL);

        for (list_item = local_sources; list_item; list_item = list_item->next) {
            source = OWR_MEDIA_SOURCE(list_item->data);
            g_object_get(source, "media-type", &source_media_type, NULL);
            if (source_media_type == media_type) {
                local_sources = g_list_remove(local_sources, source);
                owr_media_session_set_send_source(media_session, source);
                break;
            }
        }
        media_sessions = g_object_get_data(G_OBJECT(transport_agent), "media-sessions");
        media_sessions = g_list_append(media_sessions, media_session);
        g_object_set_data(G_OBJECT(transport_agent), "media-sessions", media_sessions);
        owr_transport_agent_add_session(transport_agent, OWR_SESSION(media_session));
    }
}

+ (OwrCandidate *)candidateFromObject:(NSDictionary *)candidate
{
    OwrCandidate *remote_candidate;
    OwrCandidateType candidate_type;
    OwrComponentType component_type;
    OwrTransportType transport_type;
    const gchar *cand_type, *foundation, *transport, *address, *tcp_type;
    gint priority, port;

    cand_type = [candidate[@"type"] UTF8String];

    if (!g_strcmp0(cand_type, "host"))
        candidate_type = OWR_CANDIDATE_TYPE_HOST;
    else if (!g_strcmp0(cand_type, "srflx"))
        candidate_type = OWR_CANDIDATE_TYPE_SERVER_REFLEXIVE;
    else
        candidate_type = OWR_CANDIDATE_TYPE_RELAY;

    component_type = (OwrComponentType)[candidate[@"componentId"] intValue];
    remote_candidate = owr_candidate_new(candidate_type, component_type);

    foundation = [candidate[@"foundation"] UTF8String];
    g_object_set(remote_candidate, "foundation", foundation, NULL);

    transport = [candidate[@"transport"] UTF8String];
    if (!g_strcmp0(transport, "UDP"))
        transport_type = OWR_TRANSPORT_TYPE_UDP;
    else
        transport_type = OWR_TRANSPORT_TYPE_TCP_ACTIVE;

    if (transport_type != OWR_TRANSPORT_TYPE_UDP) {
        tcp_type = [candidate[@"tcpType"] UTF8String];
        if (!g_strcmp0(tcp_type, "active"))
            transport_type = OWR_TRANSPORT_TYPE_TCP_ACTIVE;
        else if (!g_strcmp0(tcp_type, "passive"))
            transport_type = OWR_TRANSPORT_TYPE_TCP_PASSIVE;
        else
            transport_type = OWR_TRANSPORT_TYPE_TCP_SO;
    }
    g_object_set(remote_candidate, "transport-type", transport_type, NULL);

    address = [candidate[@"address"] UTF8String];
    g_object_set(remote_candidate, "address", address, NULL);

    port = [candidate[@"port"] intValue];
    g_object_set(remote_candidate, "port", port, NULL);

    priority = [candidate[@"priority"] intValue];
    g_object_set(remote_candidate, "priority", priority, NULL);

    return remote_candidate;
}

- (void)handleRemoteCandidateReceived:(NSDictionary *)candidate
{
    NSString *candidateString = [NSString stringWithFormat:@"m=application 0 NONE\r\na=%@\r\n", candidate[@"candidate"]];
    NSDictionary *mockSDP = [OpenWebRTCUtils parseSDPFromString:candidateString];

    /*
     Received DATA from peer: {"candidate":{"sdpMLineIndex":0,"sdpMid":"video","candidate":"candidate:4000241536 2 udp 2122260223 129.192.20.149 56087 typ host generation 0","candidateDescription":{"foundation":"4000241536","componentId":2,"transport":"UDP","priority":2122260223,"address":"129.192.20.149","port":56087,"type":"host"}}}
     */

    NSDictionary *mediaDescription = mockSDP[@"mediaDescriptions"][0];
    if (mediaDescription && mediaDescription[@"ice"]) {
        for (NSDictionary *candidateObject in mediaDescription[@"ice"][@"candidates"]) {
            gint index;
            GList *media_sessions;
            OwrMediaSession *media_session;
            OwrCandidate *remote_candidate;
            OwrComponentType component_type;
            gboolean rtcp_mux;
            gchar *ice_ufrag, *ice_password;

            index = [candidate[@"sdpMLineIndex"] intValue];

            media_sessions = g_object_get_data(G_OBJECT(transport_agent), "media-sessions");
            media_session = OWR_MEDIA_SESSION(g_list_nth_data(media_sessions, index));

            if (!media_session) {
                NSLog(@"[OpenWebRTCNativeHandler] WARNING! Failed to find media_session for candidate: %@", candidate);
                continue;
            }

            NSDictionary *candidateDescription = candidate[@"candidateDescription"];
            remote_candidate = [OpenWebRTCNativeHandler candidateFromObject:candidateDescription];

            ice_ufrag = g_object_get_data(G_OBJECT(media_session), "remote-ice-ufrag");
            ice_password = g_object_get_data(G_OBJECT(media_session), "remote-ice-password");
            g_object_set(remote_candidate, "ufrag", ice_ufrag, "password", ice_password, NULL);
            g_object_get(media_session, "rtcp-mux", &rtcp_mux, NULL);
            g_object_get(remote_candidate, "component-type", &component_type, NULL);
            if (!rtcp_mux || component_type != OWR_COMPONENT_TYPE_RTCP) {
                owr_session_add_remote_candidate(OWR_SESSION(media_session), remote_candidate);
            }

            NSLog(@"[OpenWebRTCNativeHandler] Handled candidate: %@", candidate);
        }
    } else {
        NSLog(@"[OpenWebRTCNativeHandler] WARNING! Failed to parse ICE candidate: %@", candidate);
    }
}

- (void)startGetCaptureSourcesForAudio:(BOOL)audio video:(BOOL)video
{
    OwrMediaType types;
    if (audio && video) {
        types = OWR_MEDIA_TYPE_AUDIO | OWR_MEDIA_TYPE_VIDEO;
    } else if (audio) {
        types = OWR_MEDIA_TYPE_AUDIO;
    } else {
        types = OWR_MEDIA_TYPE_VIDEO;
    }

    owr_get_capture_sources(types, (OwrCaptureSourcesCallback)got_local_sources, NULL);
}

#pragma mark - C stuff

static GList *local_sources, *renderers;
static OwrTransportAgent *transport_agent;
static gchar *candidate_types[] = { "host", "srflx", "relay", NULL };
static gchar *tcp_types[] = { "", "active", "passive", "so", NULL };

static void got_local_sources(GList *sources);

static void got_remote_source(OwrMediaSession *media_session, OwrMediaSource *source,
                              gpointer user_data)
{
    OwrMediaType media_type;
    gchar *name = NULL;
    OwrMediaRenderer *renderer;

    g_return_if_fail(OWR_IS_MEDIA_SESSION(media_session));
    g_return_if_fail(!user_data);

    g_object_get(source, "media-type", &media_type, "name", &name, NULL);
    g_message("Got remote source: %s", name);

    if (media_type == OWR_MEDIA_TYPE_AUDIO)
        renderer = OWR_MEDIA_RENDERER(owr_audio_renderer_new());
    else if (media_type == OWR_MEDIA_TYPE_VIDEO)
        renderer = OWR_MEDIA_RENDERER(owr_video_renderer_new(NULL));
    else
        g_return_if_reached();

    owr_media_renderer_set_source(renderer, source);
    renderers = g_list_append(renderers, renderer);
}

static gboolean can_send_answer()
{
    GObject *media_session;
    GList *media_sessions, *item;

    media_sessions = g_object_get_data(G_OBJECT(transport_agent), "media-sessions");
    for (item = media_sessions; item; item = item->next) {
        media_session = G_OBJECT(item->data);
        if (!GPOINTER_TO_UINT(g_object_get_data(media_session, "gathering-done"))
            || !g_object_get_data(media_session, "fingerprint"))
            return FALSE;
    }

    return TRUE;
}

static void got_candidate(GObject *media_session, OwrCandidate *candidate, gpointer user_data)
{
    GList *local_candidates;
    g_return_if_fail(!user_data);

    local_candidates = g_object_get_data(media_session, "local-candidates");
    local_candidates = g_list_append(local_candidates, candidate);
    g_object_set_data(media_session, "local-candidates", local_candidates);
}

static void candidate_gathering_done(GObject *media_session, gpointer user_data)
{
    g_return_if_fail(!user_data);
    g_object_set_data(media_session, "gathering-done", GUINT_TO_POINTER(1));

    NSLog(@"############################# candidate_gathering_done -> should send answer!");

    if (can_send_answer())
        send_answer();
}

static void got_dtls_certificate(GObject *media_session, GParamSpec *pspec, gpointer user_data)
{
    guint i;
    gchar *pem, *line;
    guchar *der, *tmp;
    gchar **lines;
    gint state = 0;
    guint save = 0;
    gsize der_length = 0;
    GChecksum *checksum;
    guint8 *digest;
    gsize digest_length;
    GString *fingerprint;

    g_return_if_fail(G_IS_PARAM_SPEC(pspec));
    g_return_if_fail(!user_data);

    g_object_get(media_session, "dtls-certificate", &pem, NULL);
    der = tmp = g_new0(guchar, (strlen(pem) / 4) * 3 + 3);
    lines = g_strsplit(pem, "\n", 0);
    for (i = 0, line = lines[i]; line; line = lines[++i]) {
        if (line[0] && !g_str_has_prefix(line, "-----"))
            tmp += g_base64_decode_step(line, strlen(line), tmp, &state, &save);
    }
    der_length = tmp - der;
    checksum = g_checksum_new(G_CHECKSUM_SHA256);
    digest_length = g_checksum_type_get_length(G_CHECKSUM_SHA256);
    digest = g_new(guint8, digest_length);
    g_checksum_update(checksum, der, der_length);
    g_checksum_get_digest(checksum, digest, &digest_length);
    fingerprint = g_string_new(NULL);
    for (i = 0; i < digest_length; i++) {
        if (i)
            g_string_append(fingerprint, ":");
        g_string_append_printf(fingerprint, "%02X", digest[i]);
    }
    g_object_set_data(media_session, "fingerprint", g_string_free(fingerprint, FALSE));

    g_free(digest);
    g_checksum_free(checksum);
    g_free(der);
    g_strfreev(lines);

    if (can_send_answer())
        send_answer();
}

/*
static void answer_sent(SoupSession *soup_session, GAsyncResult *result, gpointer user_data)
{
    GInputStream *input_stream;
    g_return_if_fail(!user_data);

    input_stream = soup_session_send_finish(soup_session, result, NULL);
    if (!input_stream)
        g_warning("Failed to send answer to server");
    else
        g_object_unref(input_stream);
}
 */

static void send_answer()
{
    GList *media_sessions, *item;
    GObject *media_session;
    gchar *media_type, *encoding_name;
    gboolean rtcp_mux;
    guint payload_type, clock_rate, channels;
    gboolean ccm_fir, nack_pli;
    GList *candidates, *list_item;
    OwrCandidate *candidate;
    gchar *ice_ufrag, *ice_password;
    gchar *fingerprint;

    NSMutableDictionary *sdp = [NSMutableDictionary dictionary];

    media_sessions = g_object_get_data(G_OBJECT(transport_agent), "media-sessions");

    NSMutableArray *mediaDescriptions = [NSMutableArray array];

    for (item = media_sessions; item; item = item->next) {
        media_session = G_OBJECT(item->data);

        NSMutableDictionary *mediaDescription = [NSMutableDictionary dictionary];
        media_type = g_object_steal_data(media_session, "media-type");
        mediaDescription[@"type"] = [NSString stringWithUTF8String:media_type];

        g_object_get(media_session, "rtcp-mux", &rtcp_mux, NULL);
        mediaDescription[@"rtcp"] = @{@"mux": [NSNumber numberWithBool:rtcp_mux]};

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];
        encoding_name = g_object_steal_data(media_session, "encoding-name");
        payload[@"encodingName"] = [NSString stringWithUTF8String:encoding_name];

        payload_type = GPOINTER_TO_UINT(g_object_steal_data(media_session, "payload-type"));
        payload[@"type"] = [NSNumber numberWithInt:payload_type];

        clock_rate = GPOINTER_TO_UINT(g_object_steal_data(media_session, "clock-rate"));
        payload[@"clockRate"] = [NSNumber numberWithInt:clock_rate];

        if (!g_strcmp0(media_type, "audio")) {
            channels = GPOINTER_TO_UINT(g_object_steal_data(media_session, "channels"));
            payload[@"channels"] = [NSNumber numberWithInt:channels];

        } else if (!g_strcmp0(media_type, "video")) {
            ccm_fir = GPOINTER_TO_UINT(g_object_steal_data(media_session, "ccm-fir"));
            payload[@"ccmfir"] = [NSNumber numberWithBool:ccm_fir];
            nack_pli = GPOINTER_TO_UINT(g_object_steal_data(media_session, "nack-pli"));
            payload[@"nackpli"] = [NSNumber numberWithBool:nack_pli];
        } else {
            g_warn_if_reached();
        }

        mediaDescription[@"payloads"] = @[payload];

        NSMutableDictionary *ice = [NSMutableDictionary dictionary];
        candidates = g_object_steal_data(media_session, "local-candidates");
        candidate = OWR_CANDIDATE(candidates->data);
        g_object_get(candidate, "ufrag", &ice_ufrag, "password", &ice_password, NULL);

        ice[@"ufrag"] = [NSString stringWithUTF8String:ice_ufrag];
        ice[@"password"] = [NSString stringWithUTF8String:ice_password];

        NSMutableArray *candidatesArray = [NSMutableArray array];
        for (list_item = candidates; list_item; list_item = list_item->next) {
            OwrCandidateType candidate_type;
            OwrComponentType component_type;
            OwrTransportType transport_type;
            gchar *foundation, *address, *related_address;
            gint port, priority, related_port;
            candidate = OWR_CANDIDATE(list_item->data);
            g_object_get(candidate, "type", &candidate_type, "component-type", &component_type,
                         "foundation", &foundation, "transport-type", &transport_type, "address", &address,
                         "port", &port, "priority", &priority, "base-address", &related_address,
                         "base-port", &related_port, NULL);

            NSMutableDictionary *currentCandidate = [NSMutableDictionary dictionary];
            currentCandidate[@"foundation"] = [NSString stringWithUTF8String:foundation];
            currentCandidate[@"componentId"] = [NSNumber numberWithInt:component_type];
            currentCandidate[@"transport"] = transport_type == OWR_TRANSPORT_TYPE_UDP ? @"UDP" : @"TCP";
            currentCandidate[@"priority"] = [NSNumber numberWithInt:priority];
            currentCandidate[@"address"] = [NSString stringWithUTF8String:address];
            currentCandidate[@"port"] = [NSNumber numberWithInt:port];
            currentCandidate[@"type"] = [NSString stringWithUTF8String:candidate_types[candidate_type]];

            if (candidate_type != OWR_CANDIDATE_TYPE_HOST) {
                currentCandidate[@"relatedAddress"] = [NSString stringWithUTF8String:related_address];
                currentCandidate[@"relatedPort"] = [NSNumber numberWithInt:related_port];
            }
            if (transport_type != OWR_TRANSPORT_TYPE_UDP) {
                currentCandidate[@"tcpType"] = [NSString stringWithUTF8String:tcp_types[transport_type]];
            }

            g_free(foundation);
            g_free(address);
            g_free(related_address);

            [candidatesArray addObject:currentCandidate];
        }
        g_list_free(candidates);

        mediaDescription[@"candidates"] = candidatesArray;
        mediaDescription[@"ice"] = ice;

        NSMutableDictionary *dtls = [NSMutableDictionary dictionary];
        dtls[@"fingerprintHashFunction"] = @"sha-256";
        fingerprint = g_object_steal_data(media_session, "fingerprint");
        dtls[@"fingerprint"] = [NSString stringWithUTF8String:fingerprint];
        dtls[@"setup"] = @"active";

        mediaDescription[@"dtls"] = dtls;

        g_free(fingerprint);
        g_free(ice_password);
        g_free(ice_ufrag);
        g_free(encoding_name);
        g_free(media_type);

        [mediaDescriptions addObject:mediaDescription];
    }

    sdp[@"mediaDescriptions"] = mediaDescriptions;

    NSString *sdpString = [OpenWebRTCUtils generateSDPFromObject:sdp];

    NSDictionary *d = @{@"sdp": @{@"sdp": sdpString, @"type": @"answer"}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:d
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *answer = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    if (staticSelf.delegate) {
        [staticSelf.delegate answerGenerated:answer];
    }
}

/*
static void got_candidate(GObject *media_session, OwrCandidate *candidate, gpointer user_data)
{
    GList *local_candidates;
    g_return_if_fail(!user_data);

    local_candidates = g_object_get_data(media_session, "local-candidates");
    local_candidates = g_list_append(local_candidates, candidate);
    g_object_set_data(media_session, "local-candidates", local_candidates);
}

static void candidate_gathering_done(GObject *media_session, gpointer user_data)
{
    g_return_if_fail(!user_data);
    g_object_set_data(media_session, "gathering-done", GUINT_TO_POINTER(1));
    if (can_send_answer())
        send_answer();
}

static void got_dtls_certificate(GObject *media_session, GParamSpec *pspec, gpointer user_data)
{
    guint i;
    gchar *pem, *line;
    guchar *der, *tmp;
    gchar **lines;
    gint state = 0;
    guint save = 0;
    gsize der_length = 0;
    GChecksum *checksum;
    guint8 *digest;
    gsize digest_length;
    GString *fingerprint;

    g_return_if_fail(G_IS_PARAM_SPEC(pspec));
    g_return_if_fail(!user_data);

    g_object_get(media_session, "dtls-certificate", &pem, NULL);
    der = tmp = g_new0(guchar, (strlen(pem) / 4) * 3 + 3);
    lines = g_strsplit(pem, "\n", 0);
    for (i = 0, line = lines[i]; line; line = lines[++i]) {
        if (line[0] && !g_str_has_prefix(line, "-----"))
            tmp += g_base64_decode_step(line, strlen(line), tmp, &state, &save);
    }
    der_length = tmp - der;
    checksum = g_checksum_new(G_CHECKSUM_SHA256);
    digest_length = g_checksum_type_get_length(G_CHECKSUM_SHA256);
    digest = g_new(guint8, digest_length);
    g_checksum_update(checksum, der, der_length);
    g_checksum_get_digest(checksum, digest, &digest_length);
    fingerprint = g_string_new(NULL);
    for (i = 0; i < digest_length; i++) {
        if (i)
            g_string_append(fingerprint, ":");
        g_string_append_printf(fingerprint, "%02X", digest[i]);
    }
    g_object_set_data(media_session, "fingerprint", g_string_free(fingerprint, FALSE));

    g_free(digest);
    g_checksum_free(checksum);
    g_free(der);
    g_strfreev(lines);

    if (can_send_answer())
        send_answer();
}

static void reset()
{
    GList *media_sessions, *item;
    OwrMediaRenderer *renderer;
    OwrMediaSession *media_session;

    if (renderers) {
        for (item = renderers; item; item = item->next) {
            renderer = OWR_MEDIA_RENDERER(item->data);
            owr_media_renderer_set_source(renderer, NULL);
        }
        g_list_free_full(renderers, g_object_unref);
        renderers = NULL;
    }
    if (transport_agent) {
        media_sessions = g_object_steal_data(G_OBJECT(transport_agent), "media-sessions");
        for (item = media_sessions; item; item = item->next) {
            media_session = OWR_MEDIA_SESSION(item->data);
            owr_media_session_set_send_source(media_session, NULL);
        }
        g_list_free(media_sessions);
        g_object_unref(transport_agent);
        transport_agent = NULL;
    }

    g_list_free(local_sources);
    local_sources = NULL;
    owr_get_capture_sources(OWR_MEDIA_TYPE_AUDIO | OWR_MEDIA_TYPE_VIDEO,
                            (OwrCaptureSourcesCallback)got_local_sources, NULL);
}

 */
//static void got_local_sources(GList *sources, gchar *url)
static void got_local_sources(GList *sources)
{
    NSLog(@"got_local_sources");

    local_sources = g_list_copy(sources);
    transport_agent = owr_transport_agent_new(FALSE);

    if (staticSelf.delegate) {
        [staticSelf.delegate gotLocalSources];
    }

    for (NSDictionary *server in staticSelf.helperServers) {
        owr_transport_agent_add_helper_server(transport_agent,
                                              (OwrHelperServerType)[server[@"type"] intValue],
                                              [server[@"address"] UTF8String],
                                              [server[@"port"] intValue],
                                              [server[@"username"] UTF8String],
                                              [server[@"password"] UTF8String]);
    }

    gboolean have_video = FALSE;
    g_assert(sources);

    while (sources) {
        gchar *name;
        OwrMediaSource *source = NULL;
        OwrMediaType media_type;
        OwrMediaType source_type;

        source = sources->data;
        g_assert(OWR_IS_MEDIA_SOURCE(source));

        g_object_get(source, "name", &name, "type", &source_type, "media-type", &media_type, NULL);

        /* We ref the sources because we want them to stay around. On iOS they will never be
         * unplugged, I expect, but it's safer this way. */
        g_object_ref(source);

        g_print("[%s/%s] %s\n", media_type == OWR_MEDIA_TYPE_AUDIO ? "audio" : "video",
                source_type == OWR_SOURCE_TYPE_CAPTURE ? "capture" : source_type == OWR_SOURCE_TYPE_TEST ? "test" : "unknown",
                name);

        if (!have_video && media_type == OWR_MEDIA_TYPE_VIDEO && source_type == OWR_SOURCE_TYPE_CAPTURE) {
            renderer = owr_video_renderer_new(SELF_VIEW_TAG);
            g_assert(renderer);

            g_object_set(renderer, "width", 640, "height", 480, "max-framerate", 30.0, NULL);

            owr_media_renderer_set_source(OWR_MEDIA_RENDERER(renderer), source);
            have_video = TRUE;
        }

        sources = sources->next;
    }
}

@end