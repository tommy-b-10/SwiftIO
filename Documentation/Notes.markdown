
# Notes

## IPV6

https://en.wikipedia.org/wiki/IPv6#Transition_mechanisms

https://tools.ietf.org/html/rfc4038

https://developer.apple.com/videos/play/wwdc2015/719/

https://developer.apple.com/library/mac/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/UnderstandingandPreparingfortheIPv6Transition/UnderstandingandPreparingfortheIPv6Transition.html#//apple_ref/doc/uid/TP40010220-CH213-SW1

## Addresses:

### ::1

http://v6decode.com/#address=::1

### fe80::1

http://v6decode.com/#address=fe80::1

### [::ffff:10.1.1.1]

## AF_INET vs PF_INET

  print(PF_INET, AF_INET, PF_INET6, AF_INET6)
2 2 30 30

## Sizes

print(sizeof(in_addr), sizeof(in6_addr))
4 16
  
print(sizeof(sockaddr), sizeof(sockaddr_in), sizeof(sockaddr_in6), sizeof(sockaddr_storage))
16 16 28 128

struct sockaddr {
	__uint8_t	sa_len;		/* total length */
	sa_family_t	sa_family;	/* [XSI] address family */
	char		sa_data[14];	/* [XSI] addr value (actually larger) */
};

#define	_SS_MAXSIZE	128
#define	_SS_ALIGNSIZE	(sizeof(__int64_t))
#define	_SS_PAD1SIZE	\
		(8 - sizeof(__uint8_t) - sizeof(sa_family_t))
#define	_SS_PAD2SIZE	\
		(_SS_MAXSIZE - sizeof(__uint8_t) - sizeof(sa_family_t) - \
				_SS_PAD1SIZE - _SS_ALIGNSIZE)


struct sockaddr_storage {
	__uint8_t	ss_len;		/* address length */
	sa_family_t	ss_family;	/* [XSI] address family */
	char			__ss_pad1[_SS_PAD1SIZE]; // 6
	__int64_t	__ss_align;	/* force structure storage alignment */ // 8
	char			__ss_pad2[_SS_PAD2SIZE]; // 112
};


struct sockaddr_in {
	__uint8_t	sin_len;
	sa_family_t	sin_family;
	in_port_t	sin_port;
	struct	in_addr sin_addr;
	char		sin_zero[8];
};

struct sockaddr_in6 {
	__uint8_t	sin6_len;	/* length of this struct(sa_family_t) */
	sa_family_t	sin6_family;	/* AF_INET6 (sa_family_t) */
	in_port_t	sin6_port;	/* Transport layer port # (in_port_t) */
	__uint32_t	sin6_flowinfo;	/* IP6 flow information */
	struct in6_addr	sin6_addr;	/* IP6 address */
	__uint32_t	sin6_scope_id;	/* scope zone index */
};



### Banned IPV4

inet_addr()
inet_aton()
inet_lnaof()
inet_makeaddr()
inet_netof()
inet_network()
inet_ntoa()
inet_ntoa_r()
bindresvport()
getipv4sourcefilter()
setipv4sourcefilter()

## sockaddr

In this codebase we've tried to reduce reliance on `sockaddr_in` & `sockaddr_in6` and instead rely on `sockaddr_storage`.


