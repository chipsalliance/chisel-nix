// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

package org.chipsalliance.gcd

import chisel3._
import chisel3.experimental.hierarchy.{instantiable, public, Instance, Instantiate}
import chisel3.experimental.{SerializableModule, SerializableModuleParameter}
import chisel3.probe.{define, Probe, ProbeValue}
import chisel3.properties.{AnyClassType, Class, Property}
import chisel3.util.{DecoupledIO, Valid}

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
  val width:         Property[Int]     = IO(Output(Property[Int]()))
  val useAsyncReset: Property[Boolean] = IO(Output(Property[Boolean]()))
  width         := Property(parameter.width)
  useAsyncReset := Property(parameter.useAsyncReset)
}

/** Interface of [[GCD]]. */
class GCDInterface(parameter: GCDParameter) extends Bundle {
  val clock  = Input(Clock())
  val reset  = Input(if (parameter.useAsyncReset) AsyncReset() else Bool())
  val input  = Flipped(DecoupledIO(new Bundle {
    val x = UInt(parameter.width.W)
    val y = UInt(parameter.width.W)
  }))
  val output = Valid(UInt(parameter.width.W))
  val probe  = Output(Probe(new GCDProbe(parameter), layers.Verification))
  val om     = Output(Property[AnyClassType]())
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
  val busy        = y =/= 0.U

  when(x > y) { x := x - y }.otherwise { y := y - x }

  when(io.input.fire) {
    x           := io.input.bits.x
    y           := io.input.bits.y
    startupFlag := true.B
  }

  io.input.ready  := !busy
  io.output.bits  := x
  io.output.valid := startupFlag && !busy

  // Assign Probe
  val probeWire: GCDProbe = Wire(new GCDProbe(parameter))
  define(io.probe, ProbeValue(probeWire))
  probeWire.busy := busy

  // Assign Metadata
  val omInstance: Instance[GCDOM] = Instantiate(new GCDOM(parameter))
  io.om := omInstance.getPropertyReference.asAnyClassType
}
