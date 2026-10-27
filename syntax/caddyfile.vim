" Vim syntax file
" Language: Caddyfile
" Maintainer: gmr458
" Last Change: 2026 Oct 26

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

" Heredocs can span many lines.  Start at the top of the file so that the
" region is recognized no matter where highlighting is synchronized.
syn sync fromstart

" Delimiters -----------------------------------------------------------------

syn match caddyBrace /[{}]/

" Comments -------------------------------------------------------------------

syn match caddyComment /\%(^\|\s\)\zs#.*$/ contains=caddyTodo
syn keyword caddyTodo TODO FIXME XXX NOTE HACK contained

" Strings and heredocs -------------------------------------------------------

syn region caddyString start=/"/ skip=/\\\\./ end=/"/ contains=caddyEscape,caddyPlaceholder,caddyEnvVar
syn region caddyBacktick start=/`/ end=/`/ contains=caddyPlaceholder,caddyEnvVar

syn match caddyEscape /\\["\\]/ contained

syn region caddyHeredoc
      \ matchgroup=caddyHeredocMarker
      \ start=/\%(^\|\s\)\zs<<\z([A-Za-z0-9_-]\+\)\s*$/
      \ end=/^\s*\z1\s*$/
      \ keepend

" Placeholders and environment variables -------------------------------------

syn match caddyPlaceholder /{[^{}[:space:]]\+}/
syn match caddyEnvVar /{\$[A-Za-z_][A-Za-z0-9_]*\%(:[^{}]*\)\?}/

" Paths and content types -----------------------------------------------------

syn match caddyPath /\%(^\|\s\)\zs\%(unix\/\)\=\%(\/\|\.\.\?\/\|\~\/\)[^[:space:],{}"`]*/
syn match caddyPath /\%(^\|\s\)\zs[A-Za-z]:[\\\/][^[:space:],{}"`]*/
syn match caddyContentType /\c\%(^\|\s\)\zs\%(application\|audio\|example\|font\|image\|message\|model\|multipart\|text\|video\)\/[[:alnum:]*][[:alnum:]!#$&^_.+*~-]*\%(;\s*[[:alnum:]!#$&^_.+*~-]\+=\%([^[:space:],{}";`]*\)\)\?/

" Site addresses, snippets and named routes ----------------------------------

syn match caddySiteAddress /^\s*\zs\%(\a\+:\/\/[^[:space:]#,]*\|\*\%(\.[^[:space:]#,]*\)\?\%(:\d\+\)\?\|\%(\d\{1,3}\.\)\{3}\d\{1,3}\%(:\d\+\)\?\|\%([[:alnum:]_-]\+\.\)\+[[:alnum:]_.-]*\%(:\d\+\)\?\|\[[0-9a-fA-F:.]*\]\%(:\d\+\)\?\|localhost\%(:\d\+\)\?\|:\d\+\|{[^{}[:space:]]*}\%(:\d\+\)\?\)\%(\/[^[:space:]#,]*\)\?/
syn match caddySiteAddress /,\s*\zs[^[:space:]#,]\+/

syn match caddySnippetName /^\s*\zs([^()[:space:]]\+)\ze\s*{/
syn match caddyNamedRoute /^\s*\zs&([^()[:space:]]\+)\ze\s*{/

" Request matchers -----------------------------------------------------------

syn match caddyMatcherName /\%(^\|\s\)\zs@[[:alnum:]_-]\+/
syn keyword caddyMatcherKeyword host path path_regexp method query header header_regexp
      \ protocol tls not expression remote_ip client_ip file vars vars_regexp
      \ url_pattern early_data status

" Global options -------------------------------------------------------------

syn keyword caddyGlobalOption debug http_port https_port default_bind grace_period
      \ shutdown_delay default_sni fallback_sni order storage storage_check
      \ storage_clean_interval renew_interval ocsp_interval acme_ca acme_ca_root
      \ acme_dns acme_eab cert_issuer skip_install_trust email admin on_demand_tls
      \ local_certs key_type auto_https metrics servers ocsp_stapling cert_lifetime
      \ log preferred_chains persist_config dns tls_resolvers tls_automate_names
      \ ech renewal_window_ratio pki events filesystem

" Common block subdirectives -------------------------------------------------

syn keyword caddySubdirective to dynamic lb_policy lb_retries lb_try_duration
      \ lb_try_interval lb_retry_match health_uri health_port health_interval
      \ health_passes health_fails health_timeout health_status health_body
      \ health_method health_request_body health_follow_redirects health_headers
      \ health_upstream fail_duration max_fails unhealthy_status unhealthy_latency
      \ unhealthy_request_count flush_interval request_buffers response_buffers
      \ stream_buffer_size stream_timeout stream_close_delay verbose_logs
      \ proxy_status_name trusted_proxies header_up header_down method rewrite
      \ transport handle_response replace_status copy_response copy_response_headers
      \ include exclude status defer replace match
      \ root hide index browse precompressed pass_thru disable_canonical_uris
      \ reveal_symlinks resolve_root_symlink file_limit etag_file_extensions mime
      \ between extensions
      \ try_files try_policy split_path policy first_exist smallest_size
      \ largest_size most_recently_modified fs strip_prefix strip_suffix
      \ protocols ciphers curves client_auth alpn load ca key_type eab issuer
      \ get_certificate dns resolvers propagation_delay propagation_timeout dns_ttl
      \ dns_challenge_override_domain ca_root on_demand reuse_private_keys
      \ force_automate insecure_secrets_log renewal_window_ratio
      \ sign_with_root allow_wildcard_names allow deny domains ip_ranges challenges
      \ lifetime capture_stderr env split dial_timeout read_timeout write_timeout
      \ dial_fallback_delay response_header_timeout expect_continue_timeout
      \ keepalive keepalive_interval keepalive_idle_conns
      \ keepalive_idle_conns_per_host max_conns_per_host max_idle_conns_per_host
      \ read_buffer write_buffer max_response_header network_proxy tls
      \ tls_client_auth tls_insecure_skip_verify tls_curves tls_timeout
      \ tls_trusted_ca_certs tls_trust_pool tls_server_name tls_renegotiation
      \ tls_except_ports versions compression
      \ max_header_size name listener_wrappers packet_conn_wrappers timeouts
      \ read_body read_body_idle read_header write write_idle write_max_chunk idle
      \ keepalive_count enable_full_duplex expected_underscore_headers
      \ expected_dot_headers log_credentials strict_sni_host
      \ trusted_proxies_strict trusted_proxies_unix client_ip_headers per_host
      \ trace 0rtt hostnames output format level sampling interval first
      \ thereafter core no_hostname enforce_origin origins ask permission key_id
      \ mac_key off disable_redirects disable_certs ignore_loaded_certs
      \ disable_openmetrics span span_attributes otlp observe_catchall_hosts
      \ copy_headers uri disable_checksum minimum_length gzip zstd br
      \ root_cn intermediate_cn intermediate_lifetime maintenance_interval
      \ intermediate cert key default

" Directives -----------------------------------------------------------------

syn keyword caddyDirective abort acme_server basic_auth bind copy_response
      \ copy_response_headers encode error file_server forward_auth fs handle
      \ handle_errors handle_path header intercept invoke log log_append
      \ log_name log_skip map method metrics php_fastcgi push redir request_body
      \ request_header respond reverse_proxy rewrite root route skip_log templates
      \ timeouts tracing try_files tls uri vars

syn keyword caddyDirectiveDeprecated basicauth

syn match caddyImport /^\s*\zsimport\ze[[:space:]]/ nextgroup=caddyImportPath skipwhite
syn match caddyImportPath /[^[:space:]#]\+/ contained

" Values ---------------------------------------------------------------------

syn keyword caddyBoolean on off true false
syn keyword caddyConstant local internal private_ranges first last before after
      \ bcrypt argon2id ed25519 p256 p384 rsa2048 rsa4096 h1 h2 h2c h3
      \ stdout stderr discard DEBUG INFO WARN ERROR DPANIC PANIC FATAL console json
      \ round_robin random least_conn ip_hash uri_hash

syn match caddyMethod /\c\<\%(get\|head\|post\|put\|patch\|delete\|options\|connect\|trace\)\>/

syn match caddyNumber /\<\d\+\%(\.\d\+\)\?\>/
syn match caddyDuration /\<\d\+\%(\.\d\+\)\?\%(ns\|us\|µs\|ms\|s\|m\|h\|d\)\>/
syn match caddySize /\<\d\+\%(\.\d\+\)\?\%(B\|kB\|KB\|MB\|GB\|TB\|KiB\|MiB\|GiB\|TiB\|kb\|mb\|gb\|tb\|kib\|mib\|gib\|tib\)\>/
syn match caddyStatus /\%(^\|\s\)\zs[1-5]\%(\d\d\|xx\)\ze\%(\s\|$\)/

" Operators ------------------------------------------------------------------

syn match caddyHeaderOp /\%(^\|\s\)\zs[+?>-]\ze[[:alnum:]_]/
syn match caddyRegexp /\%(^\|\s\)\zs\~\/\@![^[:space:]]\+/

" Highlighting ---------------------------------------------------------------

hi def link caddyComment Comment
hi def link caddyTodo Todo
hi def link caddyString String
hi def link caddyBacktick String
hi def link caddyEscape SpecialChar
hi def link caddyHeredoc String
hi def link caddyHeredocMarker Delimiter
hi def link caddyPlaceholder Special
hi def link caddyEnvVar PreProc
hi def link caddySiteAddress Title
hi def link caddyPath Directory
hi def link caddyContentType Type
hi def link caddySnippetName Function
hi def link caddyNamedRoute Function
hi def link caddyMatcherName Function
hi def link caddyMatcherKeyword Statement
hi def link caddyGlobalOption PreProc
hi def link caddySubdirective Identifier
hi def link caddyImport Keyword
hi def link caddyImportPath Include
hi def link caddyDirective Keyword
hi def link caddyDirectiveDeprecated Error
hi def link caddyBoolean Boolean
hi def link caddyConstant Constant
hi def link caddyMethod Type
hi def link caddyNumber Number
hi def link caddyDuration Number
hi def link caddySize Number
hi def link caddyStatus Number
hi def link caddyHeaderOp Operator
hi def link caddyRegexp String
hi def link caddyBrace Delimiter

let b:current_syntax = 'caddyfile'

let &cpo = s:cpo_save
unlet s:cpo_save
