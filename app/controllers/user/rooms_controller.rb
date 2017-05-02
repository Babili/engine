class User::RoomsController < UserController
  def index
    only_opened       = params[:only_opened] == "true"
    only_closed       = params[:only_closed] == "true"
    room_ids          = params[:room_ids]
    rooms_per_page    = params[:per_page].try(:to_i) || Room::PER_PAGE
    rooms             = current_user.rooms
    if params[:first_seen_room_id]
      first_seen_room = current_user.rooms.find_by!(public_id: params[:first_seen_room_id])
    end

    if room_ids
      rooms      = rooms.where(public_id: room_ids)
      room_count = rooms.count
      errors     = render_not_found_ids_messages(room_ids, rooms)
      return render json: { errors:  errors }, status: :not_found if errors.any?
    elsif only_opened
      rooms      = rooms.opened_for_user(current_user)
      room_count = rooms.count
    elsif only_closed
      rooms      = rooms.closed_for_user(current_user)
      room_count = rooms.count
      rooms      = rooms.before_room(rooms_per_page, first_seen_room)
    else
      room_count = rooms.count
      rooms      = rooms.before_room(rooms_per_page, first_seen_room)
    end
    rooms.includes(:users, :senders)
    render json: User::RoomPresenter.map(
      rooms:             rooms,
      room_count:        room_count,
      current_user:      current_user,
      messages_per_room: Message::PER_PAGE
    )
  end

  def show
    room = current_user.rooms.find_by!(public_id: params[:id])
    render json: User::RoomPresenter.new(
      room:              room,
      messages_per_room: Message::PER_PAGE,
      current_user:      current_user
    )
  end

  def create
    Room.transaction do
      new_room = RoomFactory.build_from_client(current_platform, current_user, params)
      if params[:no_duplicate] == "true"
        user_ids      = new_room.memberships.map(&:user_id)
        existing_room = Room.find_for_platform_for_user_ids(current_platform, user_ids)
      end
      if existing_room
        status = :ok
        room   = existing_room
      else
        status = :created
        room   = new_room
        room.save!
      end
      render json: User::RoomPresenter.new(
        room:              room,
        messages_per_room: Message::PER_PAGE,
        current_user:      current_user
      ), status: status
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { errors: [
      {
        status: 403,
        title:  "Room id already exists",
        code:   "already_exists",
        id:     "room_id"
      }
    ] }, status: :forbidden
  end

  def update
    room = current_user.rooms.find_by!(public_id: params[:id])
    RoomFactory.update_from_client(room, params)
    room.save!
    render json: User::RoomPresenter.new(
      room:              room,
      messages_per_room: Message::PER_PAGE,
      current_user:      current_user
    )
  end

  def destroy
    room = current_user.rooms.find_by!(public_id: params[:id])
    room.destroy!
    render json: User::DestroyedRoomPresenter.new(room)
  end

  private

  def render_not_found_ids_messages(room_ids, rooms)
    not_found_ids = room_ids - rooms.map(&:public_id)
    not_found_ids.map do |id|
      {
        title:  "Room not found",
        status: 404,
        code:   "not_found",
        source: { parameter: id }
      }
    end
  end
end
