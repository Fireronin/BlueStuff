/*-
 * Copyright (c) 2018-2020 Alexandre Joannou
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory (Department of Computer Science and
 * Technology) under DARPA contract HR0011-18-C-0016 ("ECATS"), as part of the
 * DARPA SSITH research programme.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 */

import Connectable :: *;
import DefaultValue :: *;

// BlueStuff import
import Routable :: *;
// BlueBasics import
import SourceSink :: *;

import AXI4_AXI4Lite_Types :: *;

////////////////////////////////////
// AXI4Lite Address Write Channel //
////////////////////////////////////////////////////////////////////////////////

// Flit type
typedef struct {
  Bit#(addr_) awaddr;
  AXI4_Prot   awprot;
  Bit#(user_) awuser;
} AXI4Lite_AWFlit#(numeric type addr_,
                   numeric type user_) deriving (Bits, FShow);
instance DefaultValue#(AXI4Lite_AWFlit#(addr_, user_));
  function defaultValue = AXI4Lite_AWFlit { awaddr: ?, awprot: 0, awuser: ? };
endinstance
instance Routable#(AXI4Lite_AWFlit#(addr_, awuser_),
                   AXI4Lite_BFlit#(wuser_),
                   Bit#(addr_));
  function routingField(x) = x.awaddr;
  module mkNoRouteFound(NoRouteFoundIfc#(AXI4Lite_AWFlit#(addr_, awuser_),
                                         AXI4Lite_BFlit#(buser_)));
    Reg#(AXI4Lite_AWFlit#(addr_, awuser_)) currentReq[2] <- mkCReg(2, ?);
    Reg#(Bool)                             pendingReq[2] <- mkCReg(2, False);
    method pushReq (req) if (!pendingReq[0]) = action
      currentReq[0] <= req;
      pendingReq[0] <= True;
    endaction;
    method getRsp if (pendingReq[1]) = actionvalue
      pendingReq[1] <= False;
      return tuple2(True, AXI4Lite_BFlit {bresp: DECERR, buser: ?});
    endactionvalue;
  endmodule
endinstance
instance DetectLast#(AXI4Lite_AWFlit#(addr_, user_));
  function detectLast(x) = True;
endinstance

// Master interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_AW_Master_Synth#(numeric type addr_, numeric type user_);
  method Bit#(addr_) awaddr;
  method AXI4_Prot   awprot;
  method Bit#(user_) awuser;
  method Bool        awvalid;
  (* prefix="" *) method Action awready(Bool awready);
endinterface

// Slave interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_AW_Slave_Synth#(numeric type addr_, numeric type user_);
  (* prefix="" *) method Action awflit ( Bool        awvalid
                                       , Bit#(addr_) awaddr
                                       , AXI4_Prot   awprot
                                       , Bit#(user_) awuser);
  method Bool awready;
endinterface

// connectable instances
instance Connectable#(AXI4Lite_AW_Master_Synth#(a, b),
                      AXI4Lite_AW_Slave_Synth#(a, b));
  module mkConnection#(AXI4Lite_AW_Master_Synth#(a,b ) m,
                       AXI4Lite_AW_Slave_Synth#(a, b) s)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect;
      s.awflit(m.awvalid, m.awaddr, m.awprot, m.awuser);
      m.awready(s.awready);
    endrule
  endmodule
endinstance
instance Connectable#(AXI4Lite_AW_Slave_Synth#(a, b),
                      AXI4Lite_AW_Master_Synth#(a, b));
  module mkConnection#(AXI4Lite_AW_Slave_Synth#(a, b) s,
                       AXI4Lite_AW_Master_Synth#(a, b) m)(Empty);
    mkConnection(m, s);
  endmodule
endinstance

/////////////////////////////////
// AXI4Lite Write Data Channel //
////////////////////////////////////////////////////////////////////////////////

// Flit type
typedef struct {
  Bit#(data_)           wdata;
  Bit#(TDiv#(data_, 8)) wstrb;
  Bit#(user_)           wuser;
} AXI4Lite_WFlit#(numeric type data_,
                  numeric type user_) deriving (Bits, FShow);
instance DefaultValue#(AXI4Lite_WFlit#(data_, user_));
  function defaultValue = AXI4Lite_WFlit { wdata: ?, wstrb: ~0, wuser: ? };
endinstance
instance DetectLast#(AXI4Lite_WFlit#(data_, user_));
  function detectLast(x) = True;
endinstance

// Master interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_W_Master_Synth#(numeric type data_, numeric type user_);
  method Bit#(data_)           wdata;
  method Bit#(TDiv#(data_, 8)) wstrb;
  method Bit#(user_)           wuser;
  method Bool                  wvalid;
  (* prefix="" *) method Action wready(Bool wready);
endinterface

// Slave interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_W_Slave_Synth#(numeric type data_, numeric type user_);
  (* prefix="" *) method Action wflit ( Bool                  wvalid
                                      , Bit#(data_)           wdata
                                      , Bit#(TDiv#(data_, 8)) wstrb
                                      , Bit#(user_)           wuser);
  method Bool wready;
endinterface

// connectable instances
instance Connectable#(AXI4Lite_W_Master_Synth#(a, b),
                      AXI4Lite_W_Slave_Synth#(a, b));
  module mkConnection#(AXI4Lite_W_Master_Synth#(a, b) m,
                       AXI4Lite_W_Slave_Synth#(a, b) s)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect;
      s.wflit(m.wvalid, m.wdata, m.wstrb, m.wuser);
      m.wready(s.wready);
    endrule
  endmodule
endinstance
instance Connectable#(AXI4Lite_W_Slave_Synth#(a, b),
                      AXI4Lite_W_Master_Synth#(a, b));
  module mkConnection#(AXI4Lite_W_Slave_Synth#(a, b) s,
                       AXI4Lite_W_Master_Synth#(a, b) m)(Empty);
    mkConnection(m, s);
  endmodule
endinstance

/////////////////////////////////////
// AXI4Lite Write Response Channel //
////////////////////////////////////////////////////////////////////////////////

// Flit type
typedef struct {
  AXI4_Resp   bresp;
  Bit#(user_) buser;
} AXI4Lite_BFlit#(numeric type user_) deriving (Bits, FShow);
instance DefaultValue#(AXI4Lite_BFlit#(user_));
  function defaultValue = AXI4Lite_BFlit { bresp: OKAY, buser: ? };
endinstance
instance DetectLast#(AXI4Lite_BFlit#(user_));
  function detectLast(x) = True;
endinstance

// Master interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_B_Master_Synth#(numeric type user_);
  (* prefix="" *) method Action bflit ( Bool        bvalid
                                      , AXI4_Resp   bresp
                                      , Bit#(user_) buser);
  method Bool bready;
endinterface

// Slave interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_B_Slave_Synth#(numeric type user_);
  method AXI4_Resp   bresp;
  method Bit#(user_) buser;
  method Bool        bvalid;
  (* prefix="" *) method Action bready(Bool bready);
endinterface

// connectable instances
instance Connectable#(AXI4Lite_B_Master_Synth#(a), AXI4Lite_B_Slave_Synth#(a));
  module mkConnection#(AXI4Lite_B_Master_Synth#(a) m,
                       AXI4Lite_B_Slave_Synth#(a) s)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect;
      m.bflit(s.bvalid, s.bresp, s.buser);
      s.bready(m.bready);
    endrule
  endmodule
endinstance
instance Connectable#(AXI4Lite_B_Slave_Synth#(a), AXI4Lite_B_Master_Synth#(a));
  module mkConnection#(AXI4Lite_B_Slave_Synth#(a) s,
                       AXI4Lite_B_Master_Synth#(a) m)(Empty);
    mkConnection(m, s);
  endmodule
endinstance

///////////////////////////////////
// AXI4Lite Read Address Channel //
////////////////////////////////////////////////////////////////////////////////

// Flit type
typedef struct {
  Bit#(addr_) araddr;
  AXI4_Prot   arprot;
  Bit#(user_) aruser;
} AXI4Lite_ARFlit#(numeric type addr_,
                   numeric type user_) deriving (Bits, FShow);
instance DefaultValue#(AXI4Lite_ARFlit#(addr_, user_));
  function defaultValue = AXI4Lite_ARFlit { araddr: ?, arprot: 0, aruser: ? };
endinstance
instance Routable#(
  AXI4Lite_ARFlit#(addr_, aruser_),
  AXI4Lite_RFlit#(data_, ruser_),
  Bit#(addr_));
  function routingField(x) = x.araddr;
  module mkNoRouteFound(NoRouteFoundIfc#(AXI4Lite_ARFlit#(addr_, aruser_),
                                         AXI4Lite_RFlit#(data_, ruser_)));
    Reg#(AXI4Lite_ARFlit#(addr_, aruser_)) currentReq[2] <- mkCReg(2, ?);
    Reg#(Bool)                             pendingReq[2] <- mkCReg(2, False);
    method pushReq (req) if (!pendingReq[0]) = action
      currentReq[0] <= req;
      pendingReq[0] <= True;
    endaction;
    method getRsp if (pendingReq[1]) = actionvalue
      pendingReq[1] <= False;
      return tuple2(True, AXI4Lite_RFlit {rdata: ?, rresp: DECERR, ruser: ?});
    endactionvalue;
  endmodule
endinstance
instance DetectLast#(AXI4Lite_ARFlit#(addr_, user_));
  function detectLast(x) = True;
endinstance

// Master interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_AR_Master_Synth#(numeric type addr_, numeric type user_);
  method Bit#(addr_) araddr;
  method AXI4_Prot   arprot;
  method Bit#(user_) aruser;
  method Bool        arvalid;
  (* prefix="" *) method Action arready(Bool arready);
endinterface

// Slave interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_AR_Slave_Synth#(numeric type addr_, numeric type user_);
  (* prefix="" *) method Action arflit ( Bool        arvalid
                                       , Bit#(addr_) araddr
                                       , AXI4_Prot   arprot
                                       , Bit#(user_) aruser);
  method Bool arready;
endinterface

// connectable instances
instance Connectable#(AXI4Lite_AR_Master_Synth#(a, b),
                      AXI4Lite_AR_Slave_Synth#(a, b));
  module mkConnection#(AXI4Lite_AR_Master_Synth#(a, b) m,
                       AXI4Lite_AR_Slave_Synth#(a, b) s)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect;
      s.arflit(m.arvalid, m.araddr, m.arprot, m.aruser);
      m.arready(s.arready);
    endrule
  endmodule
endinstance
instance Connectable#(AXI4Lite_AR_Slave_Synth#(a, b),
                      AXI4Lite_AR_Master_Synth#(a, b));
  module mkConnection#(AXI4Lite_AR_Slave_Synth#(a, b) s,
                       AXI4Lite_AR_Master_Synth#(a, b) m)(Empty);
    mkConnection(m, s);
  endmodule
endinstance

////////////////////////////////
// AXI4Lite Read Data Channel //
////////////////////////////////////////////////////////////////////////////////

// Flit type
typedef struct {
  Bit#(data_) rdata;
  AXI4_Resp   rresp;
  Bit#(user_) ruser;
} AXI4Lite_RFlit#(numeric type data_,
                  numeric type user_) deriving (Bits, FShow);
instance DefaultValue#(AXI4Lite_RFlit#(data_, user_));
  function defaultValue = AXI4Lite_RFlit { rdata: ?, rresp: OKAY, ruser: ? };
endinstance
instance DetectLast#(AXI4Lite_RFlit#(data_, user_));
  function detectLast(x) = True;
endinstance

// Master interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_R_Master_Synth#(numeric type data_, numeric type user_);
  (* prefix="" *) method Action rflit ( Bool        rvalid
                                      , Bit#(data_) rdata
                                      , AXI4_Resp   rresp
                                      , Bit#(user_) ruser);
  method Bool rready;
endinterface

// Slave interfaces
(* always_ready, always_enabled *)
interface AXI4Lite_R_Slave_Synth#(numeric type data_, numeric type user_);
  method Bit#(data_) rdata;
  method AXI4_Resp   rresp;
  method Bit#(user_) ruser;
  method Bool        rvalid;
  (* prefix="" *) method Action rready(Bool rready);
endinterface

// connectable instances
instance Connectable#(AXI4Lite_R_Master_Synth#(a, b),
                      AXI4Lite_R_Slave_Synth#(a, b));
  module mkConnection#(AXI4Lite_R_Master_Synth#(a, b) m,
                       AXI4Lite_R_Slave_Synth#(a, b) s)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect;
      m.rflit(s.rvalid, s.rdata, s.rresp, s.ruser);
      s.rready(m.rready);
    endrule
  endmodule
endinstance
instance Connectable#(AXI4Lite_R_Slave_Synth#(a, b),
                      AXI4Lite_R_Master_Synth#(a, b));
  module mkConnection#(AXI4Lite_R_Slave_Synth#(a, b) s,
                       AXI4Lite_R_Master_Synth#(a, b) m)(Empty);
    mkConnection(m, s);
  endmodule
endinstance

/////////////////////
// AXI4Lite Master //
////////////////////////////////////////////////////////////////////////////////

interface AXI4Lite_Master#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  interface Source#(AXI4Lite_AWFlit#(addr_, awuser_)) aw;
  interface Source#(AXI4Lite_WFlit#(data_, wuser_))   w;
  interface Sink#(AXI4Lite_BFlit#(buser_))            b;
  interface Source#(AXI4Lite_ARFlit#(addr_, aruser_)) ar;
  interface Sink#(AXI4Lite_RFlit#(data_, ruser_))     r;
endinterface

interface AXI4Lite_Master_Synth#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  interface AXI4Lite_AW_Master_Synth#(addr_, awuser_) aw;
  interface AXI4Lite_W_Master_Synth#(data_, wuser_)   w;
  interface AXI4Lite_B_Master_Synth#(buser_)          b;
  interface AXI4Lite_AR_Master_Synth#(addr_, aruser_) ar;
  interface AXI4Lite_R_Master_Synth#(data_, ruser_)   r;
endinterface

interface AXI4Lite_Master_Xactor#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  method Action clear;
  interface AXI4Lite_Slave#(addr_,
                             data_,
                             awuser_,
                             wuser_,
                             buser_,
                             aruser_,
                             ruser_) slave;
  interface AXI4Lite_Master_Synth#(addr_,
                                   data_,
                                   awuser_,
                                   wuser_,
                                   buser_,
                                   aruser_,
                                   ruser_) masterSynth;
endinterface

////////////////////
// AXI4Lite Slave //
////////////////////////////////////////////////////////////////////////////////

interface AXI4Lite_Slave#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  interface Sink#(AXI4Lite_AWFlit#(addr_, awuser_)) aw;
  interface Sink#(AXI4Lite_WFlit#(data_, wuser_))   w;
  interface Source#(AXI4Lite_BFlit#(buser_))        b;
  interface Sink#(AXI4Lite_ARFlit#(addr_, aruser_)) ar;
  interface Source#(AXI4Lite_RFlit#(data_, ruser_)) r;
endinterface

interface AXI4Lite_Slave_Synth#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  interface AXI4Lite_AW_Slave_Synth#(addr_, awuser_) aw;
  interface AXI4Lite_W_Slave_Synth#(data_, wuser_)   w;
  interface AXI4Lite_B_Slave_Synth#(buser_)          b;
  interface AXI4Lite_AR_Slave_Synth#(addr_, aruser_) ar;
  interface AXI4Lite_R_Slave_Synth#(data_, ruser_)   r;
endinterface

interface AXI4Lite_Slave_Xactor#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  method Action clear;
  interface AXI4Lite_Master#(addr_,
                            data_,
                            awuser_,
                            wuser_,
                            buser_,
                            aruser_,
                            ruser_) master;
  interface AXI4Lite_Slave_Synth#(addr_,
                                  data_,
                                  awuser_,
                                  wuser_,
                                  buser_,
                                  aruser_,
                                  ruser_) slaveSynth;
endinterface

////////////////////////////////////
// AXI4Lite Shim Master <-> Slave //
////////////////////////////////////////////////////////////////////////////////

interface AXI4Lite_Shim#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  method Action clear;
  interface AXI4Lite_Master#(
    addr_, data_, awuser_, wuser_, buser_, aruser_, ruser_
  ) master;
  interface AXI4Lite_Slave#(
    addr_, data_, awuser_, wuser_, buser_, aruser_, ruser_
  ) slave;
endinterface

interface AXI4Lite_Shim_Synth#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_,
  numeric type buser_,
  numeric type aruser_,
  numeric type ruser_);
  method Action clear;
  interface AXI4Lite_Master_Synth#(
    addr_, data_, awuser_, wuser_, buser_, aruser_, ruser_
  ) master;
  interface AXI4Lite_Slave_Synth#(
    addr_, data_, awuser_, wuser_, buser_, aruser_, ruser_
  ) slave;
endinterface

////////////////////////////////////
// AXI4Lite Connectable instances //
////////////////////////////////////////////////////////////////////////////////

instance Connectable#(
  AXI4Lite_Master#(a, b, c, d, e, f, g),
  AXI4Lite_Slave#(a, b, c, d, e, f, g));
  module mkConnection#(
    AXI4Lite_Master#(a, b, c, d, e, f, g) m,
    AXI4Lite_Slave#(a, b, c, d, e, f, g) s)
    (Empty);
    mkConnection(m.aw, s.aw);
    mkConnection(m.w, s.w);
    mkConnection(m.b, s.b);
    mkConnection(m.ar, s.ar);
    mkConnection(m.r, s.r);
  endmodule
endinstance
instance Connectable#(
  AXI4Lite_Slave#(a, b, c, d, e, f, g),
  AXI4Lite_Master#(a, b, c, d, e, f, g));
  module mkConnection#(
    AXI4Lite_Slave#(a, b, c, d, e, f, g) s,
    AXI4Lite_Master#(a, b, c, d, e, f, g) m)
    (Empty);
    mkConnection(m, s);
  endmodule
endinstance

instance Connectable#(
  AXI4Lite_Master_Synth#(a, b, c, d, e, f, g),
  AXI4Lite_Slave_Synth#(a, b, c, d, e, f, g));
  module mkConnection#(
    AXI4Lite_Master_Synth#(a, b, c, d, e, f, g) m,
    AXI4Lite_Slave_Synth#(a, b, c, d, e, f, g) s)
    (Empty);
    mkConnection(m.aw, s.aw);
    mkConnection(m.w, s.w);
    mkConnection(m.b, s.b);
    mkConnection(m.ar, s.ar);
    mkConnection(m.r, s.r);
  endmodule
endinstance
instance Connectable#(
  AXI4Lite_Slave_Synth#(a, b, c, d, e, f, g),
  AXI4Lite_Master_Synth#(a, b, c, d, e, f, g));
  module mkConnection#(
    AXI4Lite_Slave_Synth#(a, b, c, d, e, f, g) s,
    AXI4Lite_Master_Synth#(a, b, c, d, e, f, g) m)
    (Empty);
    mkConnection(m, s);
  endmodule
endinstance

////////////////////////////////////////
// AXI4Lite write channel helper type //
////////////////////////////////////////////////////////////////////////////////

typedef struct {
  AXI4Lite_AWFlit#(addr_, awuser_) aw;
  AXI4Lite_WFlit#(data_, wuser_)  w;
} AXI4Lite_WriteFlit#(
  numeric type addr_,
  numeric type data_,
  numeric type awuser_,
  numeric type wuser_) deriving (Bits, FShow);
instance Routable#(
  AXI4Lite_WriteFlit#(addr_, data_, awuser_, wuser_),
  AXI4Lite_BFlit#(buser_),
  Bit#(addr_)) provisos (
    Routable#(AXI4Lite_AWFlit#(addr_, awuser_),
              AXI4Lite_BFlit#(buser_),
              Bit#(addr_))
  );
  function routingField(x) = x.aw.awaddr; // XXX routingField(aw); XXX THIS SHOULD JUST WORK BUT DOESN'T ?!
  module mkNoRouteFound(NoRouteFoundIfc#(
                          AXI4Lite_WriteFlit#(addr_, data_, awuser_, wuser_),
                          AXI4Lite_BFlit#(buser_)));
    NoRouteFoundIfc#(AXI4Lite_AWFlit#(addr_, awuser_), AXI4Lite_BFlit#(buser_))
      inner <- mkNoRouteFound;
    method pushReq (req) = inner.pushReq(req.aw);
    method getRsp = inner.getRsp;
  endmodule
endinstance
instance DetectLast#(AXI4Lite_WriteFlit#(addr_, data_, awuser_, wuser_));
  function detectLast(x) = detectLast(x.w);
endinstance
