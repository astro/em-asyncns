//extern "C" {
#include "ruby.h"
#include "asyncns.h"
//};

#include <string>
#include <list>
/* EventMachine includes */
#include <project.h>


class QueryResult
{
private:
  std::list<std::string> addresses;
  const char *error;

public:
  void *q;  /* asyncns_query_t* */

  QueryResult(void *q, const char *error)
    : q(q)
    {
      this->error = error;
    }

  QueryResult(void *q, struct addrinfo *ai)
    : q(q),
      error(NULL)
    {
      struct addrinfo *i;

      for (i = ai; i; i = i->ai_next) {
        char t[256];
        const char *p;
        
        switch(i->ai_family)
        {
        case PF_INET:
          p = inet_ntop(AF_INET, &((struct sockaddr_in*) i->ai_addr)->sin_addr, t, sizeof(t));
          break;
        case PF_INET6:
          p = inet_ntop(AF_INET6, &((struct sockaddr_in6*) i->ai_addr)->sin6_addr, t, sizeof(t));
          break;
        default:
          p = NULL;
        }

        if (p)
          addresses.push_back(std::string(p));
      }
    }

  VALUE to_ruby()
    {
      if (error)
        return rb_str_new2(error);
      else
      {
        VALUE result = rb_ary_new();
        for(std::list<std::string>::iterator a = addresses.begin();
            a != addresses.end();
            ++a)
        {
          rb_ary_push(result, rb_str_new2(a->c_str()));
        }
        return result;
      }
    }
};

/**
 * This is a C++ class in the hope to eventually integrate this with
 * the C++ part of EventMachine. Until I have figured that out we're
 * going to use some Ruby glue to instruct EM to watch an fd.
 **/
class AsyncNS //: public EventableDescriptor
{
public:

  /* Ctor/dtor */

  static const int N_PROC = 1;

  static AsyncNS *create()
    {
      asyncns_t *c = asyncns_new(N_PROC);
      int fd = asyncns_fd(c);
      return new AsyncNS(c, fd/*, EventMachine*/);
    }

  AsyncNS(asyncns_t *c, int fd/*, EventMachine_t *em*/)
    : //EventableDescriptor(fd, em),
      m_asyncns(c)
    {
      /* We don't add from here for now, but leave that to the Ruby
         part:
         em->Add(this);
      */
    }

  ~AsyncNS()
    {
      asyncns_free(m_asyncns);
    }

  /* EM callbacks */

  virtual void Read()
    {
      asyncns_wait(m_asyncns, 0 /* don't block */);
    }

  /*virtual void Write()
    {
    }

  virtual void Heartbeat()
    {
    }

  virtual bool SelectForRead()
    {
      //fprintf(stderr, "asyncns_getnqueries(%p) = %i\n", m_asyncns, asyncns_getnqueries(m_asyncns));
      return (asyncns_getnqueries(m_asyncns) > 0);
    }

  virtual bool SelectForWrite()
    {
      return false;
    }*/

  /* API */

  /* Returns address of the asyncns_query_t to correlate replies in
   * Read()
   */
  void *getaddrinfo(const char *name)
    {
      struct addrinfo hints;
      asyncns_query_t *q;

      memset(&hints, 0, sizeof(hints));
      hints.ai_family = PF_UNSPEC;
      hints.ai_socktype = SOCK_STREAM;
      
      //fprintf(stderr, "asyncns_getaddrinfo(%p, %s, ...)\n", m_asyncns, name);
      q = asyncns_getaddrinfo(m_asyncns, name, NULL, &hints);
      //fprintf(stderr, "asyncns_getaddrinfo(%p, %s, ...) returned %p\n", m_asyncns, name, q);
      return q;
    }

  std::list<QueryResult> getnext()
    {
      std::list<QueryResult> result;
      asyncns_query_t *q;

      while(q = asyncns_getnext(m_asyncns))
      {
        //fprintf(stderr, "asyncns_getnext(%p) -> %p\n", m_asyncns, q);
        struct addrinfo *ai;
        int ret;

        if ((ret = asyncns_getaddrinfo_done(m_asyncns, q, &ai)))
          result.push_back(QueryResult(q, gai_strerror(ret)));
        else {
          result.push_back(QueryResult(q, ai));
          asyncns_freeaddrinfo(ai);
        }
      }

      return result;
    }

  int fd()
    {
      return asyncns_fd(m_asyncns);
    }

private:
  asyncns_t *m_asyncns;
};


static void
Asyncns_mark(AsyncNS *asyncns)
{
  //fprintf(stderr, "Asyncns_mark\n");
}

static void Asyncns_free(AsyncNS *asyncns)
{
  //fprintf(stderr, "Asyncns_free\n");
  delete asyncns;
}

/* libasyncns worker threads */
#define N_PROC 1

static VALUE Async_alloc(VALUE klass)
{
  VALUE emConns;

  /* Create */
  AsyncNS *asyncns = AsyncNS::create();
  VALUE instance = Data_Wrap_Struct(klass,
                                    Asyncns_mark, Asyncns_free,
                                    asyncns);

  /* Return new async */
  return instance;
}

static VALUE Async_fd(VALUE self)
{
  AsyncNS *asyncns;
  Data_Get_Struct(self, AsyncNS, asyncns);
  return INT2FIX(asyncns->fd());
}

static VALUE Async_getaddrinfo(VALUE self, VALUE name)
{
  AsyncNS *asyncns;
  Data_Get_Struct(self, AsyncNS, asyncns);

  void *query_id = asyncns->getaddrinfo(RSTRING_PTR(name));
  return rb_str_new(reinterpret_cast<const char *>(&query_id), sizeof(query_id));
}

static VALUE Async_read(VALUE self)
{
  AsyncNS *asyncns;
  Data_Get_Struct(self, AsyncNS, asyncns);
  asyncns->Read();

  return Qnil;
}

static VALUE Async_getnext(VALUE self)
{
  AsyncNS *asyncns;
  Data_Get_Struct(self, AsyncNS, asyncns);

  std::list<QueryResult> queries = asyncns->getnext();
  VALUE result = rb_hash_new();
  for(std::list<QueryResult>::iterator q = queries.begin();
      q != queries.end();
      ++q)
  {
    void *query_id = q->q;
    rb_hash_aset(result,
                 rb_str_new(reinterpret_cast<const char *>(&query_id), sizeof(query_id)),
                 q->to_ruby());
  }

  return result;
}

extern "C" {
  void Init_em_asyncns()
  {
    VALUE rb_mEventMachine = rb_define_module("EventMachine");
    VALUE rb_cAsyncNS = rb_define_class_under(rb_mEventMachine, "AsyncNS", rb_cObject);
    rb_define_alloc_func(rb_cAsyncNS, Async_alloc);
    rb_define_method(rb_cAsyncNS, "fd",
                     reinterpret_cast<VALUE (*)(...)>(&Async_fd), 0);
    rb_define_method(rb_cAsyncNS, "getaddrinfo",
                     reinterpret_cast<VALUE (*)(...)>(&Async_getaddrinfo), 1);
    rb_define_method(rb_cAsyncNS, "read",
                     reinterpret_cast<VALUE (*)(...)>(&Async_read), 0);
    rb_define_method(rb_cAsyncNS, "getnext",
                     reinterpret_cast<VALUE (*)(...)>(&Async_getnext), 0);
  }
}
