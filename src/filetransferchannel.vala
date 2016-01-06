using Telepathy;
using Util;

public class FileTransferChannel : Object, Telepathy.Channel, Telepathy.FileTransferChannel {
	unowned Tox tox;
	uint32 friend_number;

	public FileTransferChannel (Tox tox, uint32 friend_number, bool requested) {
		this.tox = tox;
		this.friend_number = friend_number;

		_target_handle_type = HandleType.CONTACT;
		_target_handle = friend_number + 1;
		_target_id = bin_string_to_hex (tox.friend_get_public_key (friend_number, null));
		_initiator_handle = _target_handle;
		_initiator_id = _target_id;
		_requested = requested;
	}

	public const string IFACE_CHANNEL = "org.freedesktop.Telepathy.Channel";
	
	internal HashTable<string, Variant> get_properties () {
		var properties = new HashTable<string, Variant> (str_hash, str_equal);

		properties[IFACE_CHANNEL + ".ChannelType"] = channel_type;
		properties[IFACE_CHANNEL + ".TargetHandleType"] = target_handle_type;
		properties[IFACE_CHANNEL + ".TargetHandle"] = target_handle;
		properties[IFACE_CHANNEL + ".TargetID"] = target_id;
		properties[IFACE_CHANNEL + ".InitiatorHandle"] = initiator_handle;
		properties[IFACE_CHANNEL + ".InitiatorID"] = initiator_id;
		properties[IFACE_CHANNEL + ".Requested"] = requested;
		properties[IFACE_CHANNEL + ".Interfaces"] = interfaces;

		return properties;
	}

	/* DBus name and object registration */
	DBusConnection dbusconn;
	internal ObjectPath objpath {get; private set;}
	uint[] obj_ids = {};

	internal async ObjectPath register (DBusConnection conn, ObjectPath parent) {
		debug("register %s\n", parent);

		if (objpath != null) return objpath;

		objpath = new ObjectPath("%s/%s".printf (parent, target_id));
		dbusconn = conn;

		obj_ids = {
			conn.register_object<Telepathy.Channel> (objpath, this),
			conn.register_object<Telepathy.FileTransferChannel> (objpath, this),
		};

		return objpath;
	}

	public void close () throws IOError {
		foreach (var obj_id in obj_ids) {
			dbusconn.unregister_object (obj_id);
		}
		obj_ids = {};
		closed ();
	}

	public string channel_type { owned get { return "org.freedesktop.Telepathy.Channel.Type.FileTransfer"; } }
	public string[] interfaces { owned get { return {"org.freedesktop.Telepathy.Channel.Type.FileTransfer"}; } }
	uint _target_handle;
	public uint target_handle { get { return _target_handle; } }
	string _target_id;
	public string target_id { owned get { return _target_id; } }
	uint _target_handle_type;
	public uint target_handle_type { get {return _target_handle_type; } }
	bool _requested;
	public bool requested { get { return _requested; } }
	uint _initiator_handle;
	public uint initiator_handle { get { return _initiator_handle; } }
	string _initiator_id;
	public string initiator_id { owned get { return _initiator_id; } }

	public HashTable<uint, Variant> available_socket_types {
		owned get {
			HashTable<uint, Variant> table = new HashTable<uint, Variant> (direct_hash, direct_equal);
			table.insert(Telepathy.SocketAddressType.IPV4, Telepathy.SocketAccessControl.LOCALHOST);
			return table;
		}
	}

	public Variant provide_file (uint address_type, uint access_control, Variant access_control_param) {
		assert(address_type == Telepathy.SocketAddressType.IPV4);
		return "127.0.0.1";
	}

	public Variant accept_file (uint address_type, uint access_control, Variant access_control_param, uint64 offset) {
		assert(address_type == Telepathy.SocketAddressType.IPV4);
		return "127.0.0.1";
	}
}
