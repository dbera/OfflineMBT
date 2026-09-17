/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.server.types.outline

import java.io.Serializable
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class DataTypeListEntry implements Serializable {
  static final String NODE = "node"
  static final String COLLECTION_ELEMENT = "collection-element"
  static final String MAP_KEY = "map-key"
  static final String MAP_VALUE = "map-value"
  static final String RECORD_FIELD = "record-field"
  static final String ENUM_LITERAL = "enum-literal"
  static final String PRIMITIVE_BASED_ON = "primitive-based-on"

  String nodeType
  String id
  String label
  boolean autoOpen
  List<DataTypeListEntry> children
  
  new(String nodeType, String id, String label, boolean autoOpen, List<DataTypeListEntry> children) {
    this.nodeType = nodeType ?: NODE
    this.id = id
    this.label = label
    this.autoOpen = autoOpen
    this.children = if(children === null) newArrayList() else new ArrayList(children)
  }
  
  static def collectionElement(String id, String label, List<DataTypeListEntry> children) {
    new DataTypeListEntry(COLLECTION_ELEMENT, id, label, true, children)
  }
  
  static def mapKey(String id, String label, List<DataTypeListEntry> children) {
    new DataTypeListEntry(MAP_KEY, id, label, true, children)
  }
  
  static def mapValue(String id, String label, List<DataTypeListEntry> children) {
    new DataTypeListEntry(MAP_VALUE, id, label, true, children)
  }
  
  static def recordField(String id, String label, List<DataTypeListEntry> children) {
    new DataTypeListEntry(RECORD_FIELD, id, label, children !== null && !children.isEmpty(), children)
  }
  
  static def enumLiteral(String id, String label) {
    new DataTypeListEntry(ENUM_LITERAL, id, label, false, emptyList())
  }
  
  static def primitiveBasedOn(String id, String label) {
    new DataTypeListEntry(PRIMITIVE_BASED_ON, id, label, true, emptyList())
  }
}
