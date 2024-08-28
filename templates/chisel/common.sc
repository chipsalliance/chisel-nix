// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

import mill._
import mill.scalalib._

trait HasChisel extends ScalaModule {
  // Define these for building chisel from source
  def chiselModule: Option[ScalaModule]

  override def moduleDeps = super.moduleDeps ++ chiselModule

  def chiselPluginJar: T[Option[PathRef]]

  override def scalacOptions = T(
    super.scalacOptions() ++ chiselPluginJar().map(path => s"-Xplugin:${path.path}") ++ Seq("-Ymacro-annotations")
  )

  override def scalacPluginClasspath: T[Agg[PathRef]] = T(super.scalacPluginClasspath() ++ chiselPluginJar())

  // Define these for building chisel from ivy
  def chiselIvy: Option[Dep]

  override def ivyDeps = T(super.ivyDeps() ++ chiselIvy)

  def chiselPluginIvy: Option[Dep]

  override def scalacPluginIvyDeps: T[Agg[Dep]] = T(
    super.scalacPluginIvyDeps() ++ chiselPluginIvy.map(Agg(_)).getOrElse(Agg.empty[Dep])
  )
}

trait ElaboratorModule extends ScalaModule with HasChisel {
  def generators:            Seq[ScalaModule]
  def panamaconverterModule: ScalaModule
  def circtInstallPath:      T[PathRef]
  override def moduleDeps = super.moduleDeps ++ Seq(panamaconverterModule) ++ generators
  def mainargsIvy: Dep
  override def ivyDeps = T(super.ivyDeps() ++ Seq(mainargsIvy))
  override def javacOptions = T(super.javacOptions() ++ Seq("--enable-preview", "--release", "21"))
  override def forkArgs: T[Seq[String]] = T(
    super.forkArgs() ++ Seq(
      "--enable-native-access=ALL-UNNAMED",
      "--enable-preview",
      s"-Djava.library.path=${circtInstallPath().path / "lib"}"
    )
  )
}
