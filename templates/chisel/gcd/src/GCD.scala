// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

package org.chipsalliance.gcd

import chisel3._
import chisel3.experimental.hierarchy.{instantiable, public, Instance, Instantiate}
import chisel3.experimental.{SerializableModule, SerializableModuleParameter}
import chisel3.ltl.Property.{eventually, not}
import chisel3.ltl.{AssertProperty, CoverProperty, Delay, Sequence}
import chisel3.probe.{define, Probe, ProbeValue}
import chisel3.properties.{AnyClassType, Class, Property}
import chisel3.util.circt.dpi.{RawClockedNonVoidFunctionCall, RawUnclockedNonVoidFunctionCall}
import chisel3.util.{Counter, DecoupledIO, HasExtModuleInline, RegEnable, Valid}

object GCDParameter {
  implicit def rwP: upickle.default.ReadWriter[GCDParameter] =
    upickle.default.macroRW
}

/** Parameter of [[GCD]] */
case class GCDParameter(width: Int, useAsyncReset: Boolean) extends SerializableModuleParameter

/** Verification IO of [[GCD]] */
class GCDProbe(parameter: GCDParameter) extends Bundle {
  val busy = Bool()
}

/** Metadata of [[GCD]]. */
@instantiable
class GCDOM(parameter: GCDParameter) extends Class {
  val width:         Property[Int] = IO(Output(Property[Int]()))
  val useAsyncReset: Property[Boolean] = IO(Output(Property[Boolean]()))
  width := Property(parameter.width)
  useAsyncReset := Property(parameter.useAsyncReset)
}

/** Interface of [[GCD]]. */
class GCDInterface(parameter: GCDParameter) extends Bundle {
  val clock = Input(Clock())
  val reset = Input(if (parameter.useAsyncReset) AsyncReset() else Bool())
  val input = Flipped(DecoupledIO(new Bundle {
    val x = UInt(parameter.width.W)
    val y = UInt(parameter.width.W)
  }))
  val output = Valid(UInt(parameter.width.W))
  val probe = Output(Probe(new GCDProbe(parameter), layers.Verification))
  val om = Output(Property[AnyClassType]())
}

/** Hardware Implementation of GCD */
@instantiable
class GCD(val parameter: GCDParameter)
    extends FixedIORawModule(new GCDInterface(parameter))
    with SerializableModule[GCDParameter]
    with ImplicitClock
    with ImplicitReset {
  override protected def implicitClock: Clock = io.clock
  override protected def implicitReset: Reset = io.reset

  val x: UInt = Reg(chiselTypeOf(io.input.bits.x))
  // Block X-state propagation
  val y: UInt = RegInit(chiselTypeOf(io.input.bits.x), 0.U)
  val startupFlag = RegInit(false.B)
  val busy = y =/= 0.U

  when(x > y) { x := x - y }.otherwise { y := y - x }

  when(io.input.fire) {
    x := io.input.bits.x
    y := io.input.bits.y
    startupFlag := true.B
  }

  io.input.ready := !busy
  io.output.bits := x
  io.output.valid := startupFlag && !busy

  // Assign Probe
  val probeWire: GCDProbe = Wire(new GCDProbe(parameter))
  define(io.probe, ProbeValue(probeWire))
  probeWire.busy := busy

  // Assign Metadata
  val omInstance: Instance[GCDOM] = Instantiate(new GCDOM(parameter))
  io.om := omInstance.getPropertyReference.asAnyClassType
}

object GCDTestBenchParameter {
  implicit def rwP: upickle.default.ReadWriter[GCDTestBenchParameter] =
    upickle.default.macroRW
}

/** Parameter of [[GCD]]. */
case class GCDTestBenchParameter(
  testVerbatimParameter: TestVerbatimParameter,
  gcdParameter:          GCDParameter,
  timeout:               Int,
  testSize:              Int)
    extends SerializableModuleParameter {
  require(
    (testVerbatimParameter.useAsyncReset && gcdParameter.useAsyncReset) ||
      (!testVerbatimParameter.useAsyncReset && !gcdParameter.useAsyncReset),
    "Reset Type check failed."
  )
}

@instantiable
class GCDTestBenchOM(parameter: GCDTestBenchParameter) extends Class {
  val gcd = IO(Output(Property[AnyClassType]()))
  @public
  val gcdIn = IO(Input(Property[AnyClassType]()))
  gcd := gcdIn
}

class GCDTestBenchInterface(parameter: GCDTestBenchParameter) extends Bundle {
  val om = Output(Property[AnyClassType]())
}

@instantiable
class GCDTestBench(val parameter: GCDTestBenchParameter)
    extends FixedIORawModule(new GCDTestBenchInterface(parameter))
    with SerializableModule[GCDTestBenchParameter]
    with ImplicitClock
    with ImplicitReset {
  override protected def implicitClock: Clock = verbatim.io.clock
  override protected def implicitReset: Reset = verbatim.io.reset
  // Instantiate Drivers
  val verbatim: Instance[TestVerbatim] = Instantiate(
    new TestVerbatim(parameter.testVerbatimParameter)
  )
  // Instantiate DUT.
  val dut: Instance[GCD] = Instantiate(new GCD(parameter.gcdParameter))
  // Instantiate OM
  val omInstance = Instantiate(new GCDTestBenchOM(parameter))
  io.om := omInstance.getPropertyReference.asAnyClassType
  omInstance.gcdIn := dut.io.om

  dut.io.clock := implicitClock
  dut.io.reset := implicitReset

  // Simulation Logic
  val simulationTime: UInt = RegInit(0.U(64.W))
  simulationTime := simulationTime + 1.U
  // For each timeout ticks, check it
  val (_, callWatchdog) = Counter(true.B, parameter.timeout / 2)
  val watchdogCode = RawUnclockedNonVoidFunctionCall("gcd_watchdog", UInt(8.W))(callWatchdog)
  when(watchdogCode =/= 0.U) {
    stop(cf"""{"event":"SimulationStop","reason": ${watchdogCode},"cycle":${simulationTime}}\n""")
  }
  class TestPayload extends Bundle {
    val x = UInt(parameter.gcdParameter.width.W)
    val y = UInt(parameter.gcdParameter.width.W)
    val result = UInt(parameter.gcdParameter.width.W)
  }
  val request =
    RawClockedNonVoidFunctionCall("gcd_input", Valid(new TestPayload))(
      dut.io.clock,
      !dut.io.reset.asBool && dut.io.input.ready
    )
  when(dut.io.input.ready) {
    dut.io.input.valid := request.valid
    dut.io.input.bits := request.bits
  }.otherwise {
    dut.io.input.valid := false.B;
    dut.io.input.bits := DontCare;
  }

  // LTL Checker
  import Sequence._
  val inputFire:         Sequence = dut.io.input.fire
  val inputNotFire:      Sequence = !dut.io.input.fire
  val outputFire:        Sequence = dut.io.output.valid
  val outputNotFire:     Sequence = !dut.io.output.valid
  val lastRequestResult: UInt = RegEnable(request.bits.result, dut.io.input.fire)
  val checkRight:        Sequence = lastRequestResult === dut.io.output.bits
  val inputNotValid:     Sequence = dut.io.input.ready && !dut.io.input.valid

  AssertProperty(
    inputFire |=> inputNotFire.repeatAtLeast(1) ### outputFire,
    label = Some("GCD_ALWAYS_RESPONSE")
  )
  AssertProperty(
    inputFire |=> not(inputNotFire.repeatAtLeast(1) ### (outputNotFire.and(inputFire))),
    label = Some("GCD_NO_DOUBLE_FIRE")
  )
  AssertProperty(
    outputFire |-> checkRight,
    label = Some("GCD_ASSERT_RESULT_CHECK")
  )
  // TODO: need generate $rose function in SVA
  // CoverProperty(
  //   rose(outputFire).nonConsecutiveRepeat(parameter.testSize - 1),
  //   label = Some("GCD_COVER_FIRE")
  // )
  CoverProperty(
    inputNotValid,
    label = Some("GCD_COVER_BACK_PRESSURE")
  )
}
object TestVerbatimParameter {
  implicit def rwP: upickle.default.ReadWriter[TestVerbatimParameter] =
    upickle.default.macroRW
}

case class TestVerbatimParameter(
  useAsyncReset:    Boolean,
  initFunctionName: String,
  dumpFunctionName: String,
  clockFlipTick:    Int,
  resetFlipTick:    Int)
    extends SerializableModuleParameter

@instantiable
class TestVerbatimOM(parameter: TestVerbatimParameter) extends Class {
  val useAsyncReset:    Property[Boolean] = IO(Output(Property[Boolean]()))
  val initFunctionName: Property[String] = IO(Output(Property[String]()))
  val dumpFunctionName: Property[String] = IO(Output(Property[String]()))
  val clockFlipTick:    Property[Int] = IO(Output(Property[Int]()))
  val resetFlipTick:    Property[Int] = IO(Output(Property[Int]()))
  val gcd = IO(Output(Property[AnyClassType]()))
  @public
  val gcdIn = IO(Input(Property[AnyClassType]()))
  gcd := gcdIn
  useAsyncReset := Property(parameter.useAsyncReset)
  initFunctionName := Property(parameter.initFunctionName)
  dumpFunctionName := Property(parameter.dumpFunctionName)
  clockFlipTick := Property(parameter.clockFlipTick)
  resetFlipTick := Property(parameter.resetFlipTick)
}

/** Test blackbox for clockgen, wave dump and extra testbench-only codes. */
class TestVerbatimInterface(parameter: TestVerbatimParameter) extends Bundle {
  val clock: Clock = Output(Clock())
  val reset: Reset = Output(
    if (parameter.useAsyncReset) AsyncReset() else Bool()
  )
}

@instantiable
class TestVerbatim(parameter: TestVerbatimParameter)
    extends FixedIOExtModule(new TestVerbatimInterface(parameter))
    with HasExtModuleInline {
  setInline(
    s"$desiredName.sv",
    s"""module $desiredName(output reg clock, output reg reset);
       |  export "DPI-C" function ${parameter.dumpFunctionName};
       |  function ${parameter.dumpFunctionName}(input string file);
       |`ifdef VCS
       |    $$fsdbDumpfile(file);
       |    $$fsdbDumpvars("+all");
       |    $$fsdbDumpSVA;
       |    $$fsdbDumpon;
       |`endif
       |`ifdef VERILATOR
       |    $$dumpfile(file);
       |    $$dumpvars(0);
       |`endif
       |  endfunction;
       |
       |  import "DPI-C" context function void ${parameter.initFunctionName}();
       |  initial begin
       |    ${parameter.initFunctionName}();
       |    clock = 1'b0;
       |    reset = 1'b1;
       |  end
       |  initial #(${parameter.resetFlipTick}) reset = 1'b0;
       |  always #${parameter.clockFlipTick} clock = ~clock;
       |endmodule
       |""".stripMargin
  )
}
