import CalendarTitle from "./CalendarTitle/CalendarTitle.jsx";
import CalendarTable from "./CalendarTable/CalendarTable.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";
import CalendarDetail from "./CalendarDetail/CalendarDetail.jsx";
import useDetail from "../../../hooks/useDetail.js";

function ManagerCalendar() {

    const { showDetail, setShowDetail } = useDetail();
    
    return (
        <>
            <CalendarTitle />

            <section className="content">

                <CalendarTable onView={() => setShowDetail(true)}/>

                <Pagination />

            </section>

            {showDetail ? <CalendarDetail onClose={() => setShowDetail(false)} /> : ""}
        </>
    )
}

export default ManagerCalendar;