-- Definitions of header regexps

local reconf = config['regexp']

-- Subject needs encoding
-- Define encodings types
local subject_encoded_b64 = 'Subject=/=\\?\\S+\\?B\\?/iX'
local subject_encoded_qp = 'Subject=/=\\?\\S+\\?Q\\?/iX'
-- Define whether subject must be encoded (contains non-7bit characters)
local subject_needs_mime = 'Subject=/[\\x00-\\x08\\x0b\\x0c\\x0e-\\x1f\\x7f-\\xff]/X'
-- Final rule
reconf['SUBJECT_NEEDS_ENCODING'] = string.format('!(%s) & !(%s) & (%s)', subject_encoded_b64, subject_encoded_qp, subject_needs_mime)

-- Detects that there is no space in From header (e.g. Some Name<some@host>)
reconf['R_NO_SPACE_IN_FROM'] = 'From=/\\S<[-\\w\\.]+\\@[-\\w\\.]+>/X'

-- Detects missing subject
local has_subject = 'header_exists(Subject)'
local empty_subject = 'Subject=/^$/'
-- Final rule
reconf['MISSING_SUBJECT'] = string.format('!(%s) | (%s)', has_subject, empty_subject)

-- Detects bad content-transfer-encoding for text parts
-- For text parts (text/plain and text/html mainly)
local r_ctype_text = 'content_type_is_type(text)'
-- Content transfer encoding is 7bit
local r_cte_7bit = 'compare_transfer_encoding(7bit)'
-- And body contains 8bit characters
local r_body_8bit = '/[^\\x01-\\x7f]/Pr'
reconf['R_BAD_CTE_7BIT'] = string.format('(%s) & (%s) & (%s)', r_ctype_text, r_cte_7bit, r_body_8bit)

-- Detects missing To header
reconf['MISSING_TO']= '!header_exists(To)';

-- Detects undisclosed recipients
local undisc_rcpt = 'To=/^<?undisclosed[- ]recipient/Hi'
reconf['R_UNDISC_RCPT'] = string.format('(%s) | (%s)', reconf['MISSING_TO'], undisc_rcpt)

-- Detects missing Message-Id
local has_mid = 'header_exists(Message-Id)'
reconf['MISSING_MID'] = '!header_exists(Message-Id)';

-- Received seems to be fake
reconf['R_RCVD_SPAMBOTS'] = 'Received=/^from \\[\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\] by [-.\\w+]{5,255}; [SMTWF][a-z][a-z], [\\s\\d]?\\d [JFMAJSOND][a-z][a-z] \\d{4} \\d{2}:\\d{2}:\\d{2} [-+]\\d{4}$/mH'

-- To header seems to be autogenerated
reconf['R_TO_SEEMS_AUTO'] = 'To=/\\"?(?<bt>[-.\\w]{1,64})\\"?\\s<\\k<bt>\\@/H'

-- Charset is missing in message
reconf['R_MISSING_CHARSET']= string.format('content_type_is_type(text) & !content_type_has_param(charset) & !%s', r_cte_7bit);

-- Subject seems to be spam
reconf['R_SAJDING'] = 'Subject=/\\bsajding(?:om|a)?\\b/iH'

-- Messages that have only HTML part
reconf['MIME_HTML_ONLY'] = 'has_only_html_part()'


-- Find forged Outlook MUA 
-- Yahoo groups messages
local yahoo_bulk = 'Received=/from \\[\\S+\\] by \\S+\\.(?:groups|scd|dcn)\\.yahoo\\.com with NNFMP/H'
-- Outlook MUA
local outlook_mua = 'X-Mailer=/^Microsoft Outlook\\b/H'
local any_outlook_mua = 'X-Mailer=/^Microsoft Outlook\\b/H'
reconf['FORGED_OUTLOOK_HTML'] = string.format('!%s & %s & %s', yahoo_bulk, outlook_mua, reconf['MIME_HTML_ONLY'])

-- Recipients seems to be likely with each other (only works when recipients count is more than 5 recipients)
reconf['SUSPICIOUS_RECIPS'] = 'compare_recipients_distance(0.65)'

-- Recipients list seems to be sorted
reconf['SORTED_RECIPS'] = 'is_recipients_sorted()'

-- Spam string at the end of message to make statistics faults
reconf['TRACKER_ID'] = '/^[a-z0-9]{6,24}[-_a-z0-9]{2,36}[a-z0-9]{6,24}\\s*\\z/isPr'

-- From that contains encoded characters while base 64 is not needed as all symbols are 7bit
-- Regexp that checks that from header is encoded with base64 (search in raw headers)
local from_encoded_b64 = 'From=/\\=\\?\\S+\\?B\\?/iX'
-- From contains only 7bit characters (parsed headers are used)
local from_needs_mime = 'From=/[\\x00-\\x08\\x0b\\x0c\\x0e-\\x1f\\x7f-\\xff]/H'
-- Final rule
reconf['FROM_EXCESS_BASE64'] = string.format('%s & !%s', from_encoded_b64, from_needs_mime)


-- Detect forged outlook headers
-- OE X-Mailer header
local oe_mua = 'X-Mailer=/\\bOutlook Express [456]\\./H'
-- OE Message ID format
local oe_msgid_1 = 'Message-Id=/^[A-Za-z0-9-]{7}[A-Za-z0-9]{20}\\@hotmail\\.com$/mH'
local oe_msgid_2 = 'Message-Id=/^(?:[0-9a-f]{8}|[0-9a-f]{12})\\$[0-9a-f]{8}\\$[0-9a-f]{8}\\@\\S+$/mH'
-- EZLM remail of message
local lyris_ezml_remailer = 'List-Unsubscribe=/<mailto:(?:leave-\\S+|\\S+-unsubscribe)\\@\\S+>$/H'
-- Header of wacky sendmail
local wacky_sendmail_version = 'Received=/\\/CWT\\/DCE\\)/H'
-- Iplanet received header
local iplanet_messaging_server = 'Received=/iPlanet Messaging Server/H'
-- Hotmail message id
local hotmail_baydav_msgid = 'Message-Id=/^BAY\\d+-DAV\\d+[A-Z0-9]{25}\\@phx\\.gbl$/mH'
-- Sympatico message id
local sympatico_msgid = 'Message-Id=/^BAYC\\d+-PASMTP\\d+[A-Z0-9]{25}\\@CEZ\\.ICE$/mH'
-- Message id seems to be forged
local unusable_msgid = string.format('(%s | %s | %s | %s | %s)', 
					lyris_ezml_remailer, wacky_sendmail_version, iplanet_messaging_server, hotmail_baydav_msgid, sympatico_msgid)
-- Outlook express data seems to be forged
local forged_oe = string.format('(%s & !%s & !%s & !%s)', oe_mua, oe_msgid_1, oe_msgid_2, unusable_msgid)
-- Outlook specific headers
local outlook_dollars_mua = 'X-Mailer=/^Microsoft Outlook(?: 8| CWS, Build 9|, Build 10)\\./H'
local outlook_dollars_other = 'Message-Id=/^\\!\\~\\!/mH'
local vista_msgid = 'Message-Id=/^[A-F\\d]{32}\\@\\S+$/mH'
local ims_msgid = 'Message-Id=/^[A-F\\d]{36,40}\\@\\S+$/mH'
-- Forged outlook headers
local forged_outlook_dollars = string.format('(%s & !%s & !%s & !%s & !%s & !%s',
					outlook_dollars_mua, oe_msgid_2, outlook_dollars_other, vista_msgid, ims_msgid, unusable_msgid)
-- Outlook versions that should be excluded from summary rule
local fmo_excl_o3416 = 'X-Mailer=/^Microsoft Outlook, Build 10.0.3416$/H'
local fmo_excl_oe3790 = 'X-Mailer=/^Microsoft Outlook Express 6.00.3790.3959$/H'
-- Summary rule for forged outlook
reconf['FORGED_MUA_OUTLOOK'] = string.format('(%s | %s) & !%s & !%s & !%s', 
					forged_oe, forged_outlook_dollars, fmo_excl_o3416, fmo_excl_oe3790, vista_msgid)

-- HTML outlook signs
local mime_html = 'content_type_is_type(text) & content_type_is_subtype(/.?html/)'
local tag_exists_html = 'has_html_tag(html)' 
local tag_exists_head = 'has_html_tag(head)'
local tag_exists_meta = 'has_html_tag(meta)'
local tag_exists_body = 'has_html_tag(body)'
reconf['FORGED_OUTLOOK_TAGS'] = string.format('!%s & %s & %s & !(%s & %s & %s & %s)',
					yahoo_bulk, any_outlook_mua, mime_html, tag_exists_html, tag_exists_head,
					tag_exists_meta, tag_exists_body)

-- Message id validity
local sane_msgid = 'Message-Id=/^[^<>\\\\ \\t\\n\\r\\x0b\\x80-\\xff]+\\@[^<>\\\\ \\t\\n\\r\\x0b\\x80-\\xff]+\\s*$/mH'
local msgid_comment = 'Message-Id=/\\(.*\\)/mH'
reconf['INVALID_MSGID'] = string.format('(%s) & !((%s) | (%s))', has_mid, sane_msgid, msgid_comment)


-- Only Content-Type header without other MIME headers
local cd = 'header_exists(Content-Disposition)'
local cte = 'header_exists(Content-Transfer-Encoding)'
local ct = 'header_exists(Content-Type)'
local mime_version = 'raw_header_exists(MIME-Version)'
local ct_text_plain = 'content_type_is_type(text) & content_type_is_subtype(plain)'
reconf['MIME_HEADER_CTYPE_ONLY'] = string.format('!(%s) & !(%s) & (%s) & !(%s) & !(%s)', cd, cte, ct, mime_version, ct_text_plain)


-- Forged Exchange messages
local msgid_dollars_ok = 'Message-Id=/[0-9a-f]{4,}\\$[0-9a-f]{4,}\\$[0-9a-f]{4,}\\@\\S+/Hr'
local mimeole_ms = 'X-MimeOLE=/^Produced By Microsoft MimeOLE/H'
local rcvd_with_exchange = 'Received=/with Microsoft Exchange Server/H'
reconf['R_MUA_EXCHANGE'] = 'X-MimeOLE=/Microsoft Exchange/H'
reconf['RATWARE_MS_HASH'] = string.format('(%s) & !(%s) & !(%s)', msgid_dollars_ok, mimeole_ms, rcvd_with_exchange)

-- Reply-type in content-type
reconf['STOX_REPLY_TYPE'] = 'Content-Type=/text\\/plain; .* reply-type=original/H'

-- Fake Verizon headers
local fhelo_verizon = 'X-Spam-Relays-Untrusted=/^[^\\]]+ helo=[^ ]+verizon\\.net /iH'
local fhost_verizon = 'X-Spam-Relays-Untrusted=/^[^\\]]+ rdns=[^ ]+verizon\\.net /iH'
reconf['FM_FAKE_HELO_VERIZON'] = string.format('(%s) & !(%s)', fhelo_verizon, fhost_verizon)

-- Forged yahoo msgid
local at_yahoo_msgid = 'Message-Id=/\\@yahoo\\.com\\b/iH'
local at_yahoogroups_msgid = 'Message-Id=/\\@yahoogroups\\.com\\b/iH'
local from_yahoo_com = 'From=/\\@yahoo\\.com\\b/iH'
reconf['FORGED_MSGID_YAHOO'] = string.format('(%s) & !(%s)', at_yahoo_msgid, from_yahoo_com)
local r_from_yahoo_groups = 'From=/rambler.ru\\@returns\\.groups\\.yahoo\\.com\\b/iH'
local r_from_yahoo_groups_ro = 'From=/ro.ru\\@returns\\.groups\\.yahoo\\.com\\b/iH'
reconf['FROM_CBR'] = 'From=/\\@cbr\\.ru\\b/iH'
reconf['FROM_CSHOP'] = 'From=/\\@cshop\\.ru\\b/iH'
reconf['FROM_MIRHOSTING'] = 'From=/\\@mirhosting\\.com\\b/iH'
reconf['FROM_PASSIFLORA'] = 'From=/\\@passiflora\\.ru\\b/iH'
reconf['FROM_WORLDBANK'] = 'From=/\\@worldbank\\.org\\b/iH'

-- Forged The Bat! MUA headers
local thebat_mua_v1 = 'X-Mailer=/^The Bat! \\(v1\\./H'
local ctype_has_boundary = 'Content-Type=/boundary/iH'
local bat_boundary = 'Content-Type=/boundary=\\"?-{10}/H'
local mailman_21 = 'X-Mailman-Version=/\\d/H'
reconf['FORGED_MUA_THEBAT_BOUN'] = string.format('(%s) & (%s) & !(%s) & !(%s)', thebat_mua_v1, ctype_has_boundary, bat_boundary, mailman_21)

-- Two received headers with ip addresses
local double_ip_spam_1 = 'Received=/from \\[\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\] by \\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3} with/H'
local double_ip_spam_2 = 'Received=/from\\s+\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\s+by\\s+\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3};/H'
reconf['RCVD_DOUBLE_IP_SPAM'] = string.format('(%s) | (%s)', double_ip_spam_1, double_ip_spam_2)

-- Quoted reply-to from yahoo (seems to be forged)
local repto_quote = 'Reply-To=/\\".*\\"\\s*\\</H'
local from_yahoo_com = 'From=/\\@yahoo\\.com\\b/iH'
local at_yahoo_msgid = 'Message-Id=/\\@yahoo\\.com\\b/iH'
reconf['REPTO_QUOTE_YAHOO'] = string.format('(%s) & ((%s) | (%s))', repto_quote, from_yahoo_com, at_yahoo_msgid)

-- MUA definitions
local xm_gnus = 'X-Mailer=/^Gnus v/H'
local xm_msoe5 = 'X-Mailer=/^Microsoft Outlook Express 5/H'
local xm_msoe6 = 'X-Mailer=/^Microsoft Outlook Express 6/H'
local xm_mso12 = 'X-Mailer=/^Microsoft Office Outlook 12\\.0/H'
local xm_cgpmapi = 'X-Mailer=/^CommuniGate Pro MAPI Connector/H'
local xm_moz4 = 'X-Mailer=/^Mozilla 4/H'
local xm_skyri = 'X-Mailer=/^SKYRiXgreen/H'
local xm_wwwmail = 'X-Mailer=/^WWW-Mail \\d/H'
local ua_gnus = 'User-Agent=/^Gnus/H'
local ua_knode = 'User-Agent=/^KNode/H'
local ua_mutt = 'User-Agent=/^Mutt/H'
local ua_pan = 'User-Agent=/^Pan/H'
local ua_xnews = 'User-Agent=/^Xnews/H'
local no_inr_yes_ref = string.format('(%s) | (%s) | (%s) | (%s) | (%s) | (%s) | (%s) | (%s) | (%s) | (%s) | (%s)', xm_gnus, xm_msoe5, xm_msoe6, xm_moz4, xm_skyri, xm_wwwmail, ua_gnus, ua_knode, ua_mutt, ua_pan, ua_xnews)
local subj_re = 'Subject=/^R[eE]:/H'
local has_ref = 'header_exists(References)'
local missing_ref = string.format('!(%s)', has_ref)
-- Fake reply (has RE in subject, but has not References header)
reconf['FAKE_REPLY_C'] = string.format('(%s) & (%s) & (%s) & !(%s)', subj_re, missing_ref, no_inr_yes_ref, xm_msoe6)

-- Mime-OLE is needed but absent (e.g. fake Outlook or fake Ecxchange)
local has_msmail_pri = 'header_exists(X-MSMail-Priority)'
local has_mimeole = 'header_exists(X-MimeOLE)'
local has_squirrelmail_in_mailer = 'X-Mailer=/SquirrelMail\\b/H'
reconf['MISSING_MIMEOLE'] = string.format('(%s) & !(%s) & !(%s) & !(%s) & !(%s)', has_msmail_pri, has_mimeole, has_squirrelmail_in_mailer, xm_mso12, xm_cgpmapi)

