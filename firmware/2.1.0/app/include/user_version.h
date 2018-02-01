#ifndef __USER_VERSION_H__
#define __USER_VERSION_H__

#define NODE_VERSION_MAJOR		2U
#define NODE_VERSION_MINOR		1U
#define NODE_VERSION_REVISION	0U
#define NODE_VERSION_INTERNAL   0U

#define NODE_VERSION	"Konnected firmware 2.1\r\n built on NodeMCU 2.1.0\r\n"
#ifndef BUILD_DATE
#define BUILD_DATE	  "20180201"
#endif

extern char SDK_VERSION[];

#endif	/* __USER_VERSION_H__ */
