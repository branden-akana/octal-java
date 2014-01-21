package com.octopod.utils;

import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

public enum SQLTypes {
	
	CHAR 		("CHAR"),
	VARCHAR 	("VARCHAR"),
	TINYTEXT	("TINYTEXT"),
	TEXT 		("TEXT"),
	BLOB 		("BLOB"),
	MEDIUMTEXT 	("MEDIUMTEXT"),
	MEDIUMBLOB 	("MEDIUMBLOB"),
	LONGTEXT 	("LONGTEXT"),
	LONGBLOB 	("LONGBLOB"),
	ENUM 		("ENUM"),
	SET 		("SET");
	
	private String type = null;
	private Set<String> values = null;
	private Integer size = null;
	
	SQLTypes(String type) {
		this.type = type;
		switch(type) {
			case "ENUM": case "SET":
				values = new HashSet<String>();
			case "CHAR": case "VARCHAR":
				size = 255;
		}
	}
	
	public void addValue(String value) {values.add(value);}
	public void setSize(int size) {this.size = size;}
	
	public Set<String> getValues() {return values;}
	public Integer getSize() {return size;}
	
	public String toString() {
		switch(this) {
			case ENUM: case SET:
				Iterator<String> it = values.iterator();
				if(values.size() == 0)
					return type + "()";
				StringBuilder sb = new StringBuilder();
				sb.append(it.next());
				while(it.hasNext()) {
					sb.append(",");
					sb.append(it.next());
				}
				return type + "(" + sb.toString() + ")";
			case CHAR: case VARCHAR:
				return type + "(" + size + ")";
			default:
				return type;
		}
	}

}
